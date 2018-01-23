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

    def initialize(base_dir)
      @base_dir = base_dir
      @artifacts = []
    end

    def cpp_files_in(some_dir)
      Find.find(some_dir).select { |path| CPP_EXTENSIONS.include?(File.extname(path)) }
    end

    # CPP files that are part of the project library under test
    def cpp_files
      cpp_files_in(@base_dir).reject { |p| p.start_with?(tests_dir) }
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
      # TODO: detect env!!
      full_args = ["g++"] + args
      Host.run(*full_args, **kwargs)
    end

    def test_args
      ["-I#{UNITTEST_HEADER_DIR}"] + build_args + cpp_files_arduino + cpp_files_unittest + cpp_files
    end

    def test(test_file)
      base = File.basename(test_file)
      executable = File.expand_path("unittest_#{base}.bin")
      File.delete(executable) if File.exist?(executable)
      args = ["-o", executable] + test_args + [test_file]
      return false unless run_gcc(*args)
      artifacts << executable
      Host.run(executable)
    end

  end

end
