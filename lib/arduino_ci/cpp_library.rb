require 'find'
require "arduino_ci/host"

HPP_EXTENSIONS = [".hpp", ".hh", ".h", ".hxx", ".h++"].freeze
CPP_EXTENSIONS = [".cpp", ".cc", ".c", ".cxx", ".c++"].freeze
ARDUINO_HEADER_DIR = File.expand_path("../../../cpp/arduino", __FILE__)
UNITTEST_HEADER_DIR = File.expand_path("../../../cpp/unittest", __FILE__)

module ArduinoCI

  # Information about an Arduino CPP library, specifically for compilation purposes
  class CppLibrary

    attr_reader :base_dir
    attr_reader :artifacts

    attr_reader :last_err
    attr_reader :last_out
    attr_reader :last_cmd

    def initialize(base_dir)
      @base_dir = base_dir
      @artifacts = []
      @last_err = ""
      @last_out = ""
      @last_msg = ""
    end

    def cpp_files_in(some_dir)
      Find.find(some_dir).select { |path| CPP_EXTENSIONS.include?(File.extname(path)) }
    end

    # CPP files that are part of the project library under test
    def cpp_files
      cpp_files_in(@base_dir).reject { |p| p.start_with?(tests_dir + File::SEPARATOR) }
    end

    # CPP files that are part of the arduino mock library we're providing
    def cpp_files_arduino
      cpp_files_in(ARDUINO_HEADER_DIR)
    end

    # CPP files that are part of the unit test library we're providing
    def cpp_files_unittest
      cpp_files_in(UNITTEST_HEADER_DIR)
    end

    # The directory where we expect to find unit test defintions provided by the user
    def tests_dir
      File.join(@base_dir, "test")
    end

    # The files provided by the user that contain unit tests
    def test_files
      cpp_files_in(tests_dir)
    end

    # Find all directories in the project library that include C++ header files
    def header_dirs
      files = Find.find(@base_dir).select { |path| HPP_EXTENSIONS.include?(File.extname(path)) }
      files.map { |path| File.dirname(path) }.uniq
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
    def include_args(aux_libraries)
      places = [ARDUINO_HEADER_DIR, UNITTEST_HEADER_DIR] + header_dirs + aux_libraries
      places.map { |d| "-I#{d}" }
    end

    # GCC command line arguments for features (e.g. -fno-weak)
    def feature_args(ci_gcc_config)
      return [] if ci_gcc_config[:features].nil?
      ci_gcc_config[:features].map { |f| "-f#{f}" }
    end

    # GCC command line arguments for warning (e.g. -Wall)
    def warning_args(ci_gcc_config)
      return [] if ci_gcc_config[:warnings].nil?
      ci_gcc_config[:features].map { |w| "-W#{w}" }
    end

    # GCC command line arguments for defines (e.g. -Dhave_something)
    def define_args(ci_gcc_config)
      return [] if ci_gcc_config[:defines].nil?
      ci_gcc_config[:defines].map { |d| "-D#{d}" }
    end

    # GCC command line arguments as-is
    def flag_args(ci_gcc_config)
      return [] if ci_gcc_config[:flags].nil?
      ci_gcc_config[:flags]
    end

    # All GCC command line args for building any unit test
    def test_args(aux_libraries, ci_gcc_config)
      # TODO: something with libraries?
      cgc = ci_gcc_config
      ret = include_args(aux_libraries) + cpp_files_arduino + cpp_files_unittest + cpp_files
      unless ci_gcc_config.nil?
        ret = feature_args(cgc) + warning_args(cgc) + define_args(cgc) + flag_args(cgc) + ret
      end
      ret
    end

    # build a file for running a test of the given unit test file
    def build_for_test_with_configuration(test_file, aux_libraries, ci_gcc_config)
      base = File.basename(test_file)
      executable = File.expand_path("unittest_#{base}.bin")
      File.delete(executable) if File.exist?(executable)
      args = ["-o", executable] + test_args(aux_libraries, ci_gcc_config) + [test_file]
      return nil unless run_gcc(*args)
      artifacts << executable
      executable
    end

    # run a test file
    def run_test_file(executable)
      Host.run(executable)
    end

  end

end
