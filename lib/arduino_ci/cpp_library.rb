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

    # @return [Pathname] The path to the library being tested
    attr_reader :base_dir

    # @return [Pathname] The path to the Arduino 3rd-party library directory
    attr_reader :arduino_lib_dir

    # @return [Array<Pathname>] The set of artifacts created by this class (note: incomplete!)
    attr_reader :artifacts

    # @return [String] STDERR from the last command
    attr_reader :last_err

    # @return [String] STDOUT from the last command
    attr_reader :last_out

    # @return [String] the last command
    attr_reader :last_cmd

    # @param base_dir [Pathname] The path to the library being tested
    # @param arduino_lib_dir [Pathname] The path to the libraries directory
    def initialize(base_dir, arduino_lib_dir)
      raise ArgumentError, 'base_dir is not a Pathname' unless base_dir.is_a? Pathname
      raise ArgumentError, 'arduino_lib_dir is not a Pathname' unless arduino_lib_dir.is_a? Pathname

      @base_dir = base_dir
      @arduino_lib_dir = arduino_lib_dir.expand_path
      @artifacts = []
      @last_err = ""
      @last_out = ""
      @last_msg = ""
      @has_libasan_cache = {}
    end

    # Guess whether a file is part of the vendor bundle (indicating we should ignore it).
    #
    # This assumes the vendor bundle will be at `vendor/bundle` and not some other location
    # @param path [Pathname] The path to check
    # @return [bool]
    def vendor_bundle?(path)
      # TODO: look for Gemfile, look for .bundle/config and get BUNDLE_PATH from there?
      base = @base_dir + "vendor"
      return false unless base.exist?

      vendor_bundle_aliases = [base, base.realpath]

      # we could do this but some rubies don't return an enumerator for ascend
      # path.ascend.any? { |part| vendor_bundle_aliases.include?(part) }
      path.ascend do |part|
        return true if vendor_bundle_aliases.include?(part)
      end
      false
    end

    # Guess whether a file is part of the tests/ dir (indicating library compilation should ignore it).
    #
    # @param path [Pathname] The path to check
    # @return [bool]
    def in_tests_dir?(path)
      tests_dir_aliases = [tests_dir, tests_dir.realpath]
      # we could do this but some rubies don't return an enumerator for ascend
      # path.ascend.any? { |part| tests_dir_aliases.include?(part) }
      path.ascend do |part|
        return true if tests_dir_aliases.include?(part)
      end
      false
    end

    # Check whether libasan (and by extension -fsanitizer=address) is supported
    #
    # This requires compilation of a sample program, and will be cached
    # @param gcc_binary [String]
    def libasan?(gcc_binary)
      unless @has_libasan_cache.key?(gcc_binary)
        file = Tempfile.new(["arduino_ci_libasan_check", ".cpp"])
        begin
          file.write "int main(){}"
          file.close
          @has_libasan_cache[gcc_binary] = run_gcc(gcc_binary, "-o", "/dev/null", "-fsanitize=address", file.path)
        ensure
          file.delete
        end
      end
      @has_libasan_cache[gcc_binary]
    end

    # Get a list of all CPP source files in a directory and its subdirectories
    # @param some_dir [Pathname] The directory in which to begin the search
    # @return [Array<Pathname>] The paths of the found files
    def cpp_files_in(some_dir)
      raise ArgumentError, 'some_dir is not a Pathname' unless some_dir.is_a? Pathname
      return [] unless some_dir.exist? && some_dir.directory?

      real = some_dir.realpath
      files = Find.find(real).map { |p| Pathname.new(p) }.reject(&:directory?)
      cpp = files.select { |path| CPP_EXTENSIONS.include?(path.extname.downcase) }
      not_hidden = cpp.reject { |path| path.basename.to_s.start_with?(".") }
      not_hidden.sort_by(&:to_s)
    end

    # CPP files that are part of the project library under test
    # @return [Array<Pathname>]
    def cpp_files
      cpp_files_in(@base_dir).reject { |p| vendor_bundle?(p) || in_tests_dir?(p) }
    end

    # CPP files that are part of the arduino mock library we're providing
    # @return [Array<Pathname>]
    def cpp_files_arduino
      cpp_files_in(ARDUINO_HEADER_DIR)
    end

    # CPP files that are part of the unit test library we're providing
    # @return [Array<Pathname>]
    def cpp_files_unittest
      cpp_files_in(UNITTEST_HEADER_DIR)
    end

    # CPP files that are part of the 3rd-party libraries we're including
    # @param [Array<String>] aux_libraries
    # @return [Array<Pathname>]
    def cpp_files_libraries(aux_libraries)
      arduino_library_src_dirs(aux_libraries).map { |d| cpp_files_in(d) }.flatten.uniq
    end

    # The directory where we expect to find unit test defintions provided by the user
    # @return [Pathname]
    def tests_dir
      Pathname.new(@base_dir) + "test"
    end

    # The files provided by the user that contain unit tests
    # @return [Array<Pathname>]
    def test_files
      cpp_files_in(tests_dir)
    end

    # Find all directories in the project library that include C++ header files
    # @return [Array<Pathname>]
    def header_dirs
      real = @base_dir.realpath
      all_files = Find.find(real).map { |f| Pathname.new(f) }.reject(&:directory?)
      unbundled = all_files.reject { |path| vendor_bundle?(path) }
      files = unbundled.select { |path| HPP_EXTENSIONS.include?(path.extname.downcase) }
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

    # Arduino library directories containing sources
    # @return [Array<Pathname>]
    def arduino_library_src_dirs(aux_libraries)
      # Pull in all possible places that headers could live, according to the spec:
      # https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification
      # TODO: be smart and implement library spec (library.properties, etc)?
      subdirs = ["", "src", "utility"]
      all_aux_include_dirs_nested = aux_libraries.map do |libdir|
        subdirs.map { |subdir| Pathname.new(@arduino_lib_dir) + libdir + subdir }
      end
      all_aux_include_dirs_nested.flatten.select(&:exist?).select(&:directory?)
    end

    # GCC command line arguments for including aux libraries
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

    # All GCC command line args for building any unit test
    # @param aux_libraries [Array<Pathname>] The external Arduino libraries required by this project
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [Array<String>] GCC command-line flags
    def test_args(aux_libraries, ci_gcc_config)
      # TODO: something with libraries?
      ret = include_args(aux_libraries)
      ret += cpp_files_arduino.map(&:to_s)
      ret += cpp_files_unittest.map(&:to_s)
      ret += cpp_files.map(&:to_s)
      unless ci_gcc_config.nil?
        cgc = ci_gcc_config
        ret = feature_args(cgc) + warning_args(cgc) + define_args(cgc) + flag_args(cgc) + ret
      end
      ret
    end

    # build a file for running a test of the given unit test file
    # @param test_file [Pathname] The path to the file containing the unit tests
    # @param aux_libraries [Array<Pathname>] The external Arduino libraries required by this project
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [Pathname] path to the compiled test executable
    def build_for_test_with_configuration(test_file, aux_libraries, gcc_binary, ci_gcc_config)
      base = test_file.basename
      executable = Pathname.new("unittest_#{base}.bin").expand_path
      File.delete(executable) if File.exist?(executable)
      arg_sets = []
      arg_sets << ["-std=c++0x", "-o", executable.to_s, "-DARDUINO=100"]
      if libasan?(gcc_binary)
        arg_sets << [ # Stuff to help with dynamic memory mishandling
          "-g", "-O1",
          "-fno-omit-frame-pointer",
          "-fno-optimize-sibling-calls",
          "-fsanitize=address"
        ]
      end
      arg_sets << test_args(aux_libraries, ci_gcc_config)
      arg_sets << cpp_files_libraries(aux_libraries).map(&:to_s)
      arg_sets << [test_file.to_s]
      args = arg_sets.flatten(1)
      return nil unless run_gcc(gcc_binary, *args)

      artifacts << executable
      executable
    end

    # run a test file
    # @param [Pathname] the path to the test file
    # @return [bool] whether all tests were successful
    def run_test_file(executable)
      @last_cmd = executable
      @last_out = ""
      @last_err = ""
      Host.run_and_output(executable.to_s.shellescape)
    end

  end

end
