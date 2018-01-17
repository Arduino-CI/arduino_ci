require 'find'
require "arduino_ci/host"

HPP_EXTENSIONS = [".hpp", ".hh", ".h", ".hxx", ".h++"].freeze
CPP_EXTENSIONS = [".cpp", ".cc", ".c", ".cxx", ".c++"].freeze

module ArduinoCI

  # Information about an Arduino CPP library, specifically for compilation purposes
  class CppLibrary

    attr_reader :base_dir

    def initialize(base_dir)
      @base_dir = base_dir
    end

    def cpp_files
      Find.find(@base_dir).select { |path| CPP_EXTENSIONS.include?(File.extname(path)) }
    end

    def header_dirs
      files = Find.find(@base_dir).select { |path| HPP_EXTENSIONS.include?(File.extname(path)) }
      files.map { |path| File.dirname(path) }.uniq
    end

  end

end
