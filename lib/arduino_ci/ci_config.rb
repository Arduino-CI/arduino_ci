require 'yaml'

# base config (platforms)
#   project config - .arduino_ci_platforms.yml
#     example config - .arduino_ci_plan.yml

PACKAGE_SCHEMA = {
  url: String
}.freeze

PLATFORM_SCHEMA = {
  board: String,
  package: String,
  gcc: {
    features: Array,
    defines: Array,
    warnings: Array,
    flags: Array,
  }
}.freeze

COMPILE_SCHEMA = {
  platforms: Array,
  libraries: Array,
}.freeze

UNITTEST_SCHEMA = {
  compilers: Array,
  platforms: Array,
  libraries: Array,
  testfiles: {
    select: Array,
    reject: Array,
  }
}.freeze
module ArduinoCI

  class ConfigurationError < StandardError; end

  # The filename controlling (overriding) the defaults for testing.
  # Files with this name can be used in the root directory of the Arduino library and in any/all of the example directories
  CONFIG_FILENAMES = [
    ".arduino-ci.yml",
    ".arduino-ci.yaml",
  ].freeze

  # Provide the configuration and CI plan
  # - Read from a base config with default platforms defined
  # - Allow project-specific overrides of platforms
  # - Allow example-specific allowance of platforms to test
  class CIConfig

    class << self

      # load the default set of platforms
      # @return [ArudinoCI::CIConfig] The configuration with defaults filled in
      def default
        ret = new
        ret.load_yaml(File.expand_path("../../misc/default.yml", __dir__))
        ret
      end
    end

    attr_accessor :package_info
    attr_accessor :platform_info
    attr_accessor :compile_info
    attr_accessor :unittest_info
    def initialize
      @package_info = {}
      @platform_info = {}
      @compile_info = {}
      @unittest_info = {}
    end

    # Deep-clone a hash
    # @param hash [Hash] the source data
    # @return [Hash] a copy
    def deep_clone(hash)
      Marshal.load(Marshal.dump(hash))
    end

    # validate a data source according to a schema
    # print out warnings for bad fields, and return only the good ones
    # @param rootname [String] the name, for printing
    # @param source [Hash] source data
    # @param schema [Hash] a mapping of field names to their expected type
    # @return [Hash] a copy, containing only expected & valid data
    def validate_data(rootname, source, schema)
      return nil if source.nil?

      good_data = {}
      source.each do |key, value|
        ksym = key.to_sym
        expected_type = schema[ksym].class == Class ? schema[ksym] : Hash
        if !schema.include?(ksym)
          puts "Warning: unknown field '#{ksym}' under definition for #{rootname}"
        elsif value.nil?
          good_data[ksym] = nil
        elsif value.class != expected_type
          puts "Warning: expected field '#{ksym}' of #{rootname} to be '#{expected_type}', got '#{value.class}'"
        else
          good_data[ksym] = value.class == Hash ? validate_data(key, value, schema[ksym]) : value
        end
      end
      good_data
    end

    # Load configuration yaml from a file
    # @param path [String] the source file
    # @return [ArduinoCI::CIConfig] a reference to self
    def load_yaml(path)
      yml = YAML.load_file(path)
      raise ConfigurationError, "The YAML file at #{path} failed to load" unless yml

      if yml.include?("packages")
        yml["packages"].each do |k, v|
          valid_data = validate_data("packages", v, PACKAGE_SCHEMA)
          @package_info[k] = valid_data
        end
      end

      if yml.include?("platforms")
        yml["platforms"].each do |k, v|
          valid_data = validate_data("platforms", v, PLATFORM_SCHEMA)
          @platform_info[k] = valid_data
        end
      end

      if yml.include?("compile")
        valid_data = validate_data("compile", yml["compile"], COMPILE_SCHEMA)
        valid_data.each { |k, v| @compile_info[k] = v }
      end

      if yml.include?("unittest")
        valid_data = validate_data("unittest", yml["unittest"], UNITTEST_SCHEMA)
        valid_data.each { |k, v| @unittest_info[k] = v }
      end

      self
    end

    # Override these settings with settings from another file
    # @param path [String] the path to the settings yaml file
    # @return [ArduinoCI::CIConfig] the new settings object
    def with_override(path)
      overridden_config = self.class.new
      overridden_config.package_info  = deep_clone(@package_info)
      overridden_config.platform_info = deep_clone(@platform_info)
      overridden_config.compile_info  = deep_clone(@compile_info)
      overridden_config.unittest_info = deep_clone(@unittest_info)
      overridden_config.load_yaml(path)
      overridden_config
    end

    # Get the config file at a given path, if it exists, and pass that to a block.
    # Many config files may exist, but only the first match is used
    # @param base_dir [String] The directory in which to search for a config file
    # @param val_when_no_match [Object] The value to return if no config files are found
    # @yield [path] Process the configuration file at the given path
    # @yieldparam [String] The path of an existing config file
    # @yieldreturn [ArduinoCI::CIConfig] a settings object
    # @return [ArduinoCI::CIConfig]
    def with_config(base_dir, val_when_no_match)
      CONFIG_FILENAMES.each do |f|
        path = base_dir.nil? ? f : File.join(base_dir, f)
        return (yield path) if File.exist?(path)
      end
      val_when_no_match
    end

    # Produce a configuration, assuming the CI script runs from the working directory of the base project
    # @return [ArduinoCI::CIConfig] the new settings object
    def from_project_library
      with_config(nil, self) { |path| with_override(path) }
    end

    # Produce a configuration override taken from an Arduino library example path
    # handle either path to example file or example dir
    # @param path [String] the path to the settings yaml file
    # @return [ArduinoCI::CIConfig] the new settings object
    def from_example(example_path)
      base_dir = File.directory?(example_path) ? example_path : File.dirname(example_path)
      with_config(base_dir, self) { |path| with_override(path) }
    end

    # get information about a given platform: board name, package name, compiler stuff, etc
    # @param platform_name [String] The name of the platform as defined in yaml
    # @return [Hash] the settings object
    def platform_definition(platform_name)
      defn = @platform_info[platform_name]
      return nil if defn.nil?

      deep_clone(defn)
    end

    # Whether a package is built-in to arduino
    # @param package [String] the package name (e.g. "arduino:avr")
    # @return [bool]
    def package_builtin?(package)
      package.start_with?("arduino:")
    end

    # the URL that gives the download info for a given package (a JSON file).
    # this is NOT where the package comes from.
    # @param package [String] the package name (e.g. "arduino:avr")
    # @return [String] the URL defined for this package
    def package_url(package)
      return nil if @package_info[package].nil?

      @package_info[package][:url]
    end

    # compilers to build (unit tests) with
    # @return [Array<String>] The compiler binary names (e.g. g++) to build with
    def compilers_to_use
      return [] if @unittest_info[:compilers].nil?

      @unittest_info[:compilers]
    end

    # platforms to build [the examples on]
    # @return [Array<String>] The platforms to build
    def platforms_to_build
      return [] if @compile_info[:platforms].nil?

      @compile_info[:platforms]
    end

    # platforms to unit test [the tests on]
    # @return [Array<String>] The platforms to unit test on
    def platforms_to_unittest
      return [] if @unittest_info[:platforms].nil?

      @unittest_info[:platforms]
    end

    # @return [Array<String>] The aux libraries required for building/verifying
    def aux_libraries_for_build
      return [] if @compile_info[:libraries].nil?

      @compile_info[:libraries]
    end

    # @return [Array<String>] The aux libraries required for unit testing
    def aux_libraries_for_unittest
      return [] if @unittest_info[:libraries].nil?

      @unittest_info[:libraries]
    end

    # Config allows select / reject (aka whitelist / blacklist) criteria.  Enforce on a dir
    # @param paths [Array<String>] the initial set of test files
    # @return [Array<String>] files that match the select/reject criteria
    def allowable_unittest_files(paths)
      return paths if @unittest_info[:testfiles].nil?

      ret = paths
      unless @unittest_info[:testfiles][:select].nil? || @unittest_info[:testfiles][:select].empty?
        ret = ret.select { |p| unittest_info[:testfiles][:select].any? { |glob| File.fnmatch(glob, File.basename(p)) } }
      end
      unless @unittest_info[:testfiles][:reject].nil?
        ret = ret.reject { |p| unittest_info[:testfiles][:reject].any? { |glob| File.fnmatch(glob, File.basename(p)) } }
      end
      ret
    end

    # get GCC configuration for a given platform
    # @param platform_name [String] The name of the platform as defined in yaml
    # @return [Hash] the settings
    def gcc_config(platform_name)
      plat = @platform_info[platform_name]
      return {} if plat.nil?
      return {} if plat[:gcc].nil?

      plat[:gcc]
    end
  end

end
