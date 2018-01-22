require 'yaml'

# base config (platforms)
#   project config - .arduino_ci_platforms.yml
#     example config - .arduino_ci_plan.yml

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
}.freeze

UNITTEST_SCHEMA = {
  platforms: Array,
}.freeze
module ArduinoCI

  # Provide the configuration and CI plan
  # - Read from a base config with default platforms defined
  # - Allow project-specific overrides of platforms
  # - Allow example-specific allowance of platforms to test
  class CIConfig

    class << self

      # load the default set of platforms
      def default
        ret = new
        ret.load_yaml(File.expand_path("../../../misc/default.yaml", __FILE__))
        ret
      end
    end

    attr_accessor :platform_info
    attr_accessor :compile_info
    attr_accessor :unittest_info
    def initialize
      @platform_info = {}
      @compile_info = {}
      @unittest_info = {}
    end

    def deep_clone(hash)
      Marshal.load(Marshal.dump(hash))
    end

    # validate a data source according to a schema
    # print out warnings for bad fields, and return only the good ones
    def validate_data(rootname, source, schema)
      return nil if source.nil?
      good_data = {}
      source.each do |key, value|
        ksym = key.to_sym
        expected_type = schema[ksym].class == Class ? schema[ksym] : Hash
        if !schema.include?(ksym)
          puts "Warning: unknown field '#{ksym}' under definition for #{rootname}"
        elsif value.nil?
          # unspecificed, that's fine
        elsif value.class != expected_type
          puts "Warning: expected field '#{ksym}' of #{rootname} to be '#{expected_type}', got '#{value.class}'"
        else
          good_data[ksym] = value.class == Hash ? validate_data(key, value, schema[ksym]) : value
        end
      end
      good_data
    end

    def load_yaml(path)
      yml = YAML.load_file(path)
      if yml.include?("platforms")
        yml["platforms"].each do |k, v|
          valid_data = validate_data("platforms", v, PLATFORM_SCHEMA)
          @platform_info[k] = valid_data
        end
      end

      if yml.include?("compile")
        valid_data = validate_data("compile", yml["compile"], COMPILE_SCHEMA)
        @compile_info = valid_data
      end

      if yml.include?("unittest")
        valid_data = validate_data("unittest", yml["unittest"], UNITTEST_SCHEMA)
        @unittest_info = valid_data
      end

      self
    end

    def with_override(path)
      overridden_config = self.class.new
      overridden_config.platform_info = deep_clone(@platform_info)
      overridden_config.unittest_info = deep_clone(@unittest_info)
      overridden_config.load_yaml(path)
      overridden_config
    end

    def platform_definition(platform_name)
      defn = @platform_info[platform_name]
      return nil if defn.nil?
      deep_clone(defn)
    end

  end

end
