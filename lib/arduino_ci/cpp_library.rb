require 'find'
require "arduino_ci/host"
require 'pathname'
require 'shellwords'

HPP_EXTENSIONS = [".hpp", ".hh", ".h", ".hxx", ".h++"].freeze
CPP_EXTENSIONS = [".cpp", ".cc", ".c", ".cxx", ".c++"].freeze
CI_CPP_DIR = Pathname.new(__dir__).parent.parent + "cpp"
ARDUINO_HEADER_DIR = CI_CPP_DIR + "arduino"
UNITTEST_HEADER_DIR = CI_CPP_DIR + "unittest"

module ArduinoCI

  # Information about an Arduino CPP library, specifically for compilation purposes
  class CppLibrary

    # @return [String] The official library properties file name
    LIBRARY_PROPERTIES_FILE = "library.properties".freeze

    # @return [String] The "official" name of the library, which can include spaces (in a way that the lib dir won't)
    attr_reader :name

    # @return [ArduinoBackend] The backend support for this library
    attr_reader :backend

    # @return [Array<Pathname>] The set of artifacts created by this class (note: incomplete!)
    attr_reader :artifacts

    # @return [Array<Pathname>] The set of directories that should be excluded from compilation
    attr_reader :exclude_dirs

    # @return [String] STDERR from the last command
    attr_reader :last_err

    # @return [String] STDOUT from the last command
    attr_reader :last_out

    # @return [String] the last command
    attr_reader :last_cmd

    # @return [Array<Pathname>] Directories suspected of being vendor-bundle
    attr_reader :vendor_bundle_cache

    # @param friendly_name [String] The "official" name of the library, which can contain spaces
    # @param backend [ArduinoBackend] The support backend
    def initialize(friendly_name, backend)
      raise ArgumentError, "friendly_name is not a String (got #{friendly_name.class})" unless friendly_name.is_a? String
      raise ArgumentError, 'backend is not a ArduinoBackend' unless backend.is_a? ArduinoBackend

      @name = friendly_name
      @backend = backend
      @info_cache = nil
      @artifacts = []
      @last_err = ""
      @last_out = ""
      @last_msg = ""
      @has_libasan_cache = {}
      @vendor_bundle_cache = nil
      @exclude_dirs = []
    end

    # Generate a guess as to the on-disk (coerced character) name of this library
    #
    # @TODO: delegate this to the backend in some way? It uses "official" names for install, but dir names in lists :(
    # @param friendly_name [String] The library name as it might appear in library manager
    # @return [String] How the path will be stored on disk -- spaces are coerced to underscores
    def self.library_directory_name(friendly_name)
      friendly_name.tr(" ", "_")
    end

    # Generate a guess as to the on-disk (coerced character) name of this library
    #
    # @TODO: delegate this to the backend in some way? It uses "official" names for install, but dir names in lists :(
    # @return [String] How the path will be stored on disk -- spaces are coerced to underscores
    def name_on_disk
      self.class.library_directory_name(@name)
    end

    # Get the path to this library, whether or not it exists
    # @return [Pathname] The fully qualified library path
    def path
      @backend.lib_dir + name_on_disk
    end

    # @return [String] The parent directory of all examples
    def examples_dir
      path + "examples"
    end

    # Determine whether a library is present in the lib dir
    #
    # Note that `true` doesn't guarantee that the library is valid/installed
    #  and `false` doesn't guarantee that the library isn't built-in
    #
    # @return [bool]
    def installed?
      path.exist?
    end

    # install a library by name
    # @param version [String] the version to install
    # @param recursive [bool] whether to also install its dependencies
    # @return [bool] whether the command succeeded
    def install(version = nil, recursive = false)
      return true if installed? && !recursive

      fqln = version.nil? ? @name : "#{@name}@#{version}"
      result = if recursive
        @backend.run_and_capture("lib", "install", fqln)
      else
        @backend.run_and_capture("lib", "install", "--no-deps", fqln)
      end
      result[:success]
    end

    # information about the library as reported by the backend
    # @return [Hash] the metadata object
    def info
      return nil unless installed?

      # note that if the library isn't found, we're going to do a lot of cache attempts...
      if @info_cache.nil?
        @info_cache = @backend.installed_libraries.find do |l|
          lib_info = l["library"]
          Pathname.new(lib_info["install_dir"]).realpath == path.realpath
        end
      end

      @info_cache
    end

    # @param installed_library_path [String] The library to query
    # @return [Array<String>] Example sketch files
    def example_sketches
      reported_dirs = info["library"]["examples"].map(&Pathname::method(:new))
      reported_dirs.map { |e| e + e.basename.sub_ext(".ino") }.select(&:exist?).sort_by(&:to_s)
    end

    # The expected path to the library.properties file (i.e. even if it does not exist)
    # @return [Pathname]
    def library_properties_path
      path + LIBRARY_PROPERTIES_FILE
    end

    # Whether library.properties definitions for this library exist
    # @return [bool]
    def library_properties?
      lib_props = library_properties_path
      lib_props.exist? && lib_props.file?
    end

    # Library properties
    # @return [LibraryProperties] The library.properties metadata wrapper for this library
    def library_properties
      return nil unless library_properties?

      LibraryProperties.new(library_properties_path)
    end

    # Set directories that should be excluded from compilation
    # @param rval [Array] Array of strings or pathnames that will be coerced to pathnames
    def exclude_dirs=(rval)
      @exclude_dirs = rval.map { |d| d.is_a?(Pathname) ? d : Pathname.new(d) }
    end

    # Decide whether this is a 1.5-compatible library
    #
    # This should be according to https://arduino.github.io/arduino-cli/latest/library-specification
    # but we rely on the cli to decide for us
    # @return [bool]
    def one_point_five?
      return false unless library_properties?

      src_dir = path + "src"
      src_dir.exist? && src_dir.directory?
    end

    # Guess whether a file is part of the vendor bundle (indicating we should ignore it).
    #
    # A safe way to do this seems to be to check whether any of the installed gems
    #   appear to be a subdirectory of (but not equal to) the working directory.
    #   That gets us the vendor directory (or multiple directories). We can check
    #   if the given path is contained by any of those.
    #
    # @param some_path [Pathname] The path to check
    # @return [bool]
    def vendor_bundle?(some_path)
      # Cache bundle information, as it is (1) time consuming to fetch and (2) not going to change while we run
      if @vendor_bundle_cache.nil?
        bundle_info = Host.run_and_capture("bundle show --paths")
        if !bundle_info[:success]
          # if the bundle show command fails, assume there isn't a bundle
          @vendor_bundle_cache = false
        else
          # Get all the places where gems are stored.  We combine a few things here:
          # by preemptively switching to the parent directory, we can both ensure that
          # we skip any gems that are equal to the working directory AND exploit some
          # commonality in the paths to cut down our search locations
          #
          # NOT CONFUSING THE WORKING DIRECTORY WITH VENDOR BUNDLE IS SUPER IMPORTANT
          # because if we do, we won't be able to run CI on this library itself.
          bundle_paths = bundle_info[:out].lines
                                          .map { |l| Pathname.new(l.chomp) }
                                          .select(&:exist?)
                                          .map(&:realpath)
                                          .map(&:parent)
                                          .uniq
          wd = Pathname.new(".").realpath
          @vendor_bundle_cache = bundle_paths.select do |gem_path|
            gem_path.ascend do |part|
              break true if wd == part
            end
          end
        end
      end

      # no bundle existed
      return false if @vendor_bundle_cache == false

      # With vendor bundles located, check this file against those
      @vendor_bundle_cache.any? do |gem_path|
        some_path.ascend do |part|
          break true if gem_path == part
        end
      end
    end

    # Guess whether a file is part of the tests/ dir (indicating library compilation should ignore it).
    #
    # @param path [Pathname] The path to check
    # @return [bool]
    def in_tests_dir?(sourcefile_path)
      return false unless tests_dir.exist?

      tests_dir_aliases = [tests_dir, tests_dir.realpath]
      # we could do this but some rubies don't return an enumerator for ascend
      # path.ascend.any? { |part| tests_dir_aliases.include?(part) }
      sourcefile_path.ascend do |part|
        return true if tests_dir_aliases.include?(part)
      end
      false
    end

    # Guess whether a file is part of any @excludes_dir dir (indicating library compilation should ignore it).
    #
    # @param path [Pathname] The path to check
    # @return [bool]
    def in_exclude_dir?(sourcefile_path)
      # we could do this but some rubies don't return an enumerator for ascend
      # path.ascend.any? { |part| tests_dir_aliases.include?(part) }
      sourcefile_path.ascend do |part|
        return true if exclude_dir.any? { |p| p.realpath == part.realpath }
      end
      false
    end

    # Check whether libasan (and by extension -fsanitizer=address) is supported
    #
    # This requires compilation of a sample program, and will be cached
    # @param gcc_binary [String]
    def libasan?(gcc_binary)
      unless @has_libasan_cache.key?(gcc_binary)
        Tempfile.create(["arduino_ci_libasan_check", ".cpp"]) do |file|
          file.write "int main(){}"
          file.close
          @has_libasan_cache[gcc_binary] = run_gcc(gcc_binary, "-o", "/dev/null", "-fsanitize=address", file.path)
        end
      end
      @has_libasan_cache[gcc_binary]
    end

    # Get a list of all CPP source files in a directory and its subdirectories
    # @param some_dir [Pathname] The directory in which to begin the search
    # @param extensions [Array<Sring>] The set of allowable file extensions
    # @return [Array<Pathname>] The paths of the found files
    def code_files_in(some_dir, extensions)
      raise ArgumentError, 'some_dir is not a Pathname' unless some_dir.is_a? Pathname

      full_dir = path + some_dir
      return [] unless full_dir.exist? && full_dir.directory?

      files = full_dir.children.reject(&:directory?)
      cpp = files.select { |path| extensions.include?(path.extname.downcase) }
      not_hidden = cpp.reject { |path| path.basename.to_s.start_with?(".") }
      not_hidden.sort_by(&:to_s)
    end

    # Get a list of all CPP source files in a directory and its subdirectories
    # @param some_dir [Pathname] The directory in which to begin the search
    # @param extensions [Array<Sring>] The set of allowable file extensions
    # @return [Array<Pathname>] The paths of the found files
    def code_files_in_recursive(some_dir, extensions)
      raise ArgumentError, 'some_dir is not a Pathname' unless some_dir.is_a? Pathname
      return [] unless some_dir.exist? && some_dir.directory?

      Find.find(some_dir).map { |p| Pathname.new(p) }.select(&:directory?).map { |d| code_files_in(d, extensions) }.flatten
    end

    # Source files that are part of the library under test
    # @param extensions [Array<String>] the allowed extensions (or, the ones we're looking for)
    # @return [Array<Pathname>]
    def source_files(extensions)
      source_dir = Pathname.new(info["library"]["source_dir"])
      ret = if one_point_five?
        code_files_in_recursive(source_dir, extensions)
      else
        [source_dir, source_dir + "utility"].map { |d| code_files_in(d, extensions) }.flatten
      end

      # note to future troubleshooter: some of these tests may not be relevant, but at the moment at
      # least some of them are tied to existing features
      ret.reject { |p| vendor_bundle?(p) || in_tests_dir?(p) || in_exclude_dir?(p) }
    end

    # Header files that are part of the project library under test
    # @return [Array<Pathname>]
    def header_files
      source_files(HPP_EXTENSIONS)
    end

    # CPP files that are part of the project library under test
    # @return [Array<Pathname>]
    def cpp_files
      source_files(CPP_EXTENSIONS)
    end

    # CPP files that are part of the arduino mock library we're providing
    # @return [Array<Pathname>]
    def cpp_files_arduino
      code_files_in(ARDUINO_HEADER_DIR, CPP_EXTENSIONS)
    end

    # CPP files that are part of the unit test library we're providing
    # @return [Array<Pathname>]
    def cpp_files_unittest
      code_files_in(UNITTEST_HEADER_DIR, CPP_EXTENSIONS)
    end

    # CPP files that are part of the 3rd-party libraries we're including
    # @param [Array<String>] aux_libraries
    # @return [Array<Pathname>]
    def cpp_files_libraries(aux_libraries)
      arduino_library_src_dirs(aux_libraries).map { |d| code_files_in(d, CPP_EXTENSIONS) }.flatten.uniq
    end

    # Returns the Pathnames for all paths to exclude from testing and compilation
    # @return [Array<Pathname>]
    def exclude_dir
      @exclude_dirs.map { |p| Pathname.new(path) + p }.select(&:exist?)
    end

    # The directory where we expect to find unit test defintions provided by the user
    # @return [Pathname]
    def tests_dir
      Pathname.new(path) + "test"
    end

    # The files provided by the user that contain unit tests
    # @return [Array<Pathname>]
    def test_files
      code_files_in(tests_dir, CPP_EXTENSIONS)
    end

    # Find all directories in the project library that include C++ header files
    # @return [Array<Pathname>]
    def header_dirs
      unbundled = header_files.reject { |path| vendor_bundle?(path) }
      unexcluded = unbundled.reject { |path| in_exclude_dir?(path) }
      files = unexcluded.select { |path| HPP_EXTENSIONS.include?(path.extname.downcase) }
      files.map(&:dirname).uniq
    end

    # wrapper for the GCC command
    def run_gcc(gcc_binary, *args, **kwargs)
      full_args = [gcc_binary] + args
      @last_cmd = " $ #{full_args.join(' ')}"
      ret = Host.run_and_capture(*full_args, **kwargs)
      @last_err = ret[:err]
      @last_out = ret[:out]
      ret[:success]
    end

    # Return the GCC version
    # @return [String] the version reported by `gcc -v`
    def gcc_version(gcc_binary)
      return nil unless run_gcc(gcc_binary, "-v")

      @last_err
    end

    # Get a list of all dependencies as defined in library.properties
    # @return [Array<String>] The library names of the dependencies (not the paths)
    def arduino_library_dependencies
      return [] unless library_properties?
      return [] if library_properties.depends.nil?

      library_properties.depends
    end

    # Arduino library dependencies all the way down, installing if they are not present
    # @return [Array<String>] The library names of the dependencies (not the paths)
    def all_arduino_library_dependencies!(additional_libraries = [])
      # Pull in all possible places that headers could live, according to the spec:
      # https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification
      recursive = (additional_libraries + arduino_library_dependencies).map do |n|
        other_lib = self.class.new(n, @backend)
        other_lib.install unless other_lib.installed?
        other_lib.all_arduino_library_dependencies!
      end.flatten
      (additional_libraries + recursive).uniq
    end

    # Arduino library directories containing sources -- only those of the dependencies
    # @return [Array<Pathname>]
    def arduino_library_src_dirs(aux_libraries)
      all_arduino_library_dependencies!(aux_libraries).map { |l| self.class.new(l, @backend).header_dirs }.flatten.uniq
    end

    # GCC command line arguments for including aux libraries
    #
    # This function recursively collects the library directores of the dependencies
    #
    # @param aux_libraries [Array<Pathname>] The external Arduino libraries required by this project
    # @return [Array<String>] The GCC command-line flags necessary to include those libraries
    def include_args(aux_libraries)
      all_aux_include_dirs = arduino_library_src_dirs(aux_libraries)
      places = [ARDUINO_HEADER_DIR, UNITTEST_HEADER_DIR] + header_dirs + all_aux_include_dirs
      places.map { |d| "-I#{d}" }
    end

    # GCC command line arguments for features (e.g. -fno-weak)
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [Array<String>] GCC command-line flags
    def feature_args(ci_gcc_config)
      return [] if ci_gcc_config[:features].nil?

      ci_gcc_config[:features].map { |f| "-f#{f}" }
    end

    # GCC command line arguments for warning (e.g. -Wall)
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [Array<String>] GCC command-line flags
    def warning_args(ci_gcc_config)
      return [] if ci_gcc_config[:warnings].nil?

      ci_gcc_config[:features].map { |w| "-W#{w}" }
    end

    # GCC command line arguments for defines (e.g. -Dhave_something)
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [Array<String>] GCC command-line flags
    def define_args(ci_gcc_config)
      return [] if ci_gcc_config[:defines].nil?

      ci_gcc_config[:defines].map { |d| "-D#{d}" }
    end

    # GCC command line arguments as-is
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [Array<String>] GCC command-line flags
    def flag_args(ci_gcc_config)
      return [] if ci_gcc_config[:flags].nil?

      ci_gcc_config[:flags]
    end

    # All non-CPP GCC command line args for building any unit test.
    # We leave out the CPP files so they can be included or not
    # depending on whether we are building a shared library.
    # @param aux_libraries [Array<Pathname>] The external Arduino libraries required by this project
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [Array<String>] GCC command-line flags
    def test_args(aux_libraries, ci_gcc_config)
      # TODO: something with libraries?
      ret = include_args(aux_libraries)
      unless ci_gcc_config.nil?
        cgc = ci_gcc_config
        ret = feature_args(cgc) + warning_args(cgc) + define_args(cgc) + flag_args(cgc) + ret
      end
      ret
    end

    # build a file for running a test of the given unit test file
    #
    # The dependent libraries configuration is appended with data from library.properties internal to the library under test
    #
    # @param test_file [Pathname] The path to the file containing the unit tests (nil to compile application as shared library)
    # @param aux_libraries [Array<Pathname>] The external Arduino libraries required by this project
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [Pathname] path to the compiled test executable
    def build_for_test_with_configuration(test_file, aux_libraries, gcc_binary, ci_gcc_config)
      arg_sets = []
      arg_sets << ["-std=c++0x"]
      if test_file.nil?
        executable = Pathname.new("libarduino.so").expand_path
        arg_sets << ["-shared", "-fPIC", "-Wl,-undefined,dynamic_lookup"]
      else
        base = test_file.basename
        executable = Pathname.new("unittest_#{base}.bin").expand_path
      end
      ENV["LD_LIBRARY_PATH"] = Dir.pwd
      arg_sets << ["-o", executable.to_s, "-L" + Dir.pwd]
      File.delete(executable) if File.exist?(executable)
      arg_sets << ["-DARDUINO=100"]
      if libasan?(gcc_binary)
        arg_sets << [ # Stuff to help with dynamic memory mishandling
          "-g", "-O1",
          "-fno-omit-frame-pointer",
          "-fno-optimize-sibling-calls",
          "-fsanitize=address"
        ]
      end

      # combine library.properties defs (if existing) with config file.
      # TODO: as much as I'd like to rely only on the properties file(s), I think that would prevent testing 1.0-spec libs
      # the following two take some time, so are cached when we build the shared library
      @full_dependencies ||= all_arduino_library_dependencies!(aux_libraries)
      @test_args ||= test_args(@full_dependencies, ci_gcc_config)
      arg_sets << @test_args # used cached value since building full set of include directories can take time

      if File.exist?("libarduino.so")  # add the test file and the shared library
        arg_sets << [test_file.to_s, "-larduino"]
      else  # CPP files for the shared library
        arg_sets << cpp_files_arduino.map(&:to_s)  # Arduino.cpp, Godmode.cpp, and stdlib.cpp
        arg_sets << cpp_files_unittest.map(&:to_s) # ArduinoUnitTests.cpp
        arg_sets << cpp_files.map(&:to_s) # CPP files for the primary application library under test
        arg_sets << cpp_files_libraries(@full_dependencies).map(&:to_s) # CPP files for all the libraries we depend on
        arg_sets << [test_file.to_s] if test_file
      end

      args = arg_sets.flatten(1)
      return nil unless run_gcc(gcc_binary, *args)

      artifacts << executable
      executable
    end

    # print any found stack dumps
    # @param executable [Pathname] the path to the test file
    def print_stack_dump(executable)
      possible_dumpfiles = [
        executable.sub_ext("#{executable.extname}.stackdump")
      ]
      possible_dumpfiles.select(&:exist?).each do |dump|
        puts "========== Stack dump from #{dump}:"
        File.foreach(dump) { |line| print "    #{line}" }
      end
    end

    # run a test file
    # @param executable [Pathname] the path to the test file
    # @return [bool] whether all tests were successful
    def run_test_file(executable)
      @last_cmd = executable
      @last_out = ""
      @last_err = ""
      ret = Host.run_and_output(executable.to_s.shellescape)

      # print any stack traces found during a failure
      print_stack_dump(executable) unless ret

      ret
    end

  end

end
