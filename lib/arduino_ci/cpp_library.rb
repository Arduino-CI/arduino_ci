require 'find'
require "arduino_ci/host"

HPP_EXTENSIONS = [".hpp", ".hh", ".h", ".hxx", ".h++"].freeze
CPP_EXTENSIONS = [".cpp", ".cc", ".c", ".cxx", ".c++"].freeze
ARDUINO_HEADER_DIR = File.expand_path("../../../cpp/arduino", __FILE__)
UNITTEST_HEADER_DIR = File.expand_path("../../../cpp/unittest", __FILE__)

module ArduinoCI

  # Information about an Arduino CPP library, specifically for compilation purposes
  class CppLibrary

    # @return [String] The path to the library being tested
    attr_reader :base_dir

    # @return [Array<String>] The set of artifacts created by this class (note: incomplete!)
    attr_reader :artifacts

    # @return [String] STDERR from the last command
    attr_reader :last_err

    # @return [String] STDOUT from the last command
    attr_reader :last_out

    # @return [String] the last command
    attr_reader :last_cmd

    # @param base_dir [String] The path to the library being tested
    def initialize(base_dir)
      @base_dir = File.expand_path(base_dir)
      @artifacts = []
      @last_err = ""
      @last_out = ""
      @last_msg = ""
    end

    # Guess whether a file is part of the vendor bundle (indicating we should ignore it).
    #
    # This assumes the vendor bundle will be at `vendor/bundle` and not some other location
    # @param path [String] The path to check
    # @return [Array<String>] The paths of the found files
    def vendor_bundle?(path)
      # TODO: look for Gemfile, look for .bundle/config and get BUNDLE_PATH from there?
      base = File.join(@base_dir, "vendor")
      real = File.join(File.realpath(@base_dir), "vendor")
      return true if path.start_with?(base)
      return true if path.start_with?(real)
      false
    end

    # Get a list of all CPP source files in a directory and its subdirectories
    # @param some_dir [String] The directory in which to begin the search
    # @return [Array<String>] The paths of the found files
    def cpp_files_in(some_dir)
      real = File.realpath(some_dir)
      files = Find.find(real).reject { |path| File.directory?(path) }
      ret = files.select { |path| CPP_EXTENSIONS.include?(File.extname(path)) }
      ret
    end

    # CPP files that are part of the project library under test
    # @return [Array<String>]
    def cpp_files
      real_tests_dir = File.realpath(tests_dir)
      cpp_files_in(@base_dir).reject do |p|
        next true if File.dirname(p).include?(tests_dir)
        next true if File.dirname(p).include?(real_tests_dir)
        next true if vendor_bundle?(p)
      end
    end

    # CPP files that are part of the arduino mock library we're providing
    # @return [Array<String>]
    def cpp_files_arduino
      cpp_files_in(ARDUINO_HEADER_DIR)
    end

    # CPP files that are part of the unit test library we're providing
    # @return [Array<String>]
    def cpp_files_unittest
      cpp_files_in(UNITTEST_HEADER_DIR)
    end

    # The directory where we expect to find unit test defintions provided by the user
    # @return [String]
    def tests_dir
      File.join(@base_dir, "test")
    end

    # The files provided by the user that contain unit tests
    # @return [Array<String>]
    def test_files
      cpp_files_in(tests_dir)
    end

    # Find all directories in the project library that include C++ header files
    # @return [Array<String>]
    def header_dirs
      real = File.realpath(@base_dir)
      all_files = Find.find(real).reject { |path| File.directory?(path) }
      unbundled = all_files.reject { |path| vendor_bundle?(path) }
      files = unbundled.select { |path| HPP_EXTENSIONS.include?(File.extname(path)) }
      ret = files.map { |path| File.dirname(path) }.uniq
      ret
    end

    # wrapper for the GCC command
    def run_gcc(*args, **kwargs)
      pipe_out, pipe_out_wr = IO.pipe
      pipe_err, pipe_err_wr = IO.pipe
      full_args = ["g++"] + args
      @last_cmd = " $ #{full_args.join(' ')}"
      our_kwargs = { out: pipe_out_wr, err: pipe_err_wr }
      eventual_kwargs = our_kwargs.merge(kwargs)
      success = Host.run(*full_args, **eventual_kwargs)

      pipe_out_wr.close
      pipe_err_wr.close
      str_out = pipe_out.read
      str_err = pipe_err.read
      pipe_out.close
      pipe_err.close
      @last_err = str_err
      @last_out = str_out
      success
    end

    # GCC command line arguments for including aux libraries
    # @param aux_libraries [String] The external Arduino libraries required by this project
    # @return [Array<String>] The GCC command-line flags necessary to include those libraries
    def include_args(aux_libraries)
      places = [ARDUINO_HEADER_DIR, UNITTEST_HEADER_DIR] + header_dirs + aux_libraries
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
    # @param aux_libraries [String] The external Arduino libraries required by this project
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [Array<String>] GCC command-line flags
    def test_args(aux_libraries, ci_gcc_config)
      # TODO: something with libraries?
      ret = include_args(aux_libraries) + cpp_files_arduino + cpp_files_unittest + cpp_files
      unless ci_gcc_config.nil?
        cgc = ci_gcc_config
        ret = feature_args(cgc) + warning_args(cgc) + define_args(cgc) + flag_args(cgc) + ret
      end
      ret
    end

    # build a file for running a test of the given unit test file
    # @param test_file [String] The path to the file containing the unit tests
    # @param aux_libraries [String] The external Arduino libraries required by this project
    # @param ci_gcc_config [Hash] The GCC config object
    # @return [String] path to the compiled test executable
    def build_for_test_with_configuration(test_file, aux_libraries, ci_gcc_config)
      base = File.basename(test_file)
      executable = File.expand_path("unittest_#{base}.bin")
      File.delete(executable) if File.exist?(executable)
      args = ["-std=c++11", "-o", executable] + test_args(aux_libraries, ci_gcc_config) + [test_file]
      return nil unless run_gcc(*args)
      artifacts << executable
      executable
    end

    # run a test file
    # @param [String] the path to the test file
    # @return [bool] whether all tests were successful
    def run_test_file(executable)
      @last_cmd = executable
      @last_out = ""
      @last_err = ""
      Host.run(executable)
    end

  end

end
