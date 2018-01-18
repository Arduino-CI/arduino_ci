require 'find'
require "arduino_ci/host"

HPP_EXTENSIONS = [".hpp", ".hh", ".h", ".hxx", ".h++"].freeze
CPP_EXTENSIONS = [".cpp", ".cc", ".c", ".cxx", ".c++"].freeze
ARDUINO_HEADER_DIR = File.expand_path("../../../cpp", __FILE__)

module ArduinoCI

  # Information about an Arduino CPP library, specifically for compilation purposes
  class CppLibrary

    attr_reader :base_dir

    def initialize(base_dir)
      @base_dir = base_dir
    end

    def cpp_files
      all_cpp = Find.find(@base_dir).select { |path| CPP_EXTENSIONS.include?(File.extname(path)) }
      all_cpp.reject { |p| p.start_with?(tests_dir) }
    end

    def tests_dir
      File.join(@base_dir, "test")
    end

    def test_files
      Find.find(tests_dir).select { |path| CPP_EXTENSIONS.include?(File.extname(path)) }
    end

    def header_dirs
      files = Find.find(@base_dir).select { |path| HPP_EXTENSIONS.include?(File.extname(path)) }
      files.map { |path| File.dirname(path) }.uniq
    end

    def build_args
      ["-I#{ARDUINO_HEADER_DIR}"] + header_dirs.map { |d| "-I#{d}" } + cpp_files
    end

    def build(arduino_cmd)
      args = ["-c", "-o", "arduino_ci_built.bin"] + build_args
      arduino_cmd.run_gcc(*args)
    end

  end

end
