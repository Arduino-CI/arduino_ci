require 'fileutils'
require 'pathname'
require 'json'

# workaround for https://github.com/arduino/Arduino/issues/3535
WORKAROUND_LIB = "USBHost".freeze

module ArduinoCI

  # To report errors that we can't resolve or possibly even explain
  class ArduinoExecutionError < StandardError; end

  # Wrap the Arduino executable.  This requires, in some cases, a faked display.
  class ArduinoBackend

    # We never even use this in code, it's just here for reference because the backend is picky about it. Used for testing
    # @return [String] the only allowable name for the arduino-cli config file.
    CONFIG_FILE_NAME = "arduino-cli.yaml".freeze

    # Unfortunately we need error messaging around this quirk
    # @return [String] The text to use for user apologies regarding the config file
    CONFIG_FILE_APOLOGY = "Sorry this is weird, see https://github.com/arduino/arduino-cli/issues/753".freeze

    # the actual path to the executable on this platform
    # @return [Pathname]
    attr_accessor :binary_path

    # The directory that contains the config file
    # @return [Pathname]
    attr_reader :config_dir

    # @return [String] STDOUT of the most recently-run command
    attr_reader   :last_out

    # @return [String] STDERR of the most recently-run command
    attr_reader   :last_err

    # @return [String] the most recently-run command
    attr_reader   :last_msg

    # @return [Array<String>] Additional URLs for the boards manager
    attr_reader   :additional_urls

    def initialize(binary_path)
      @binary_path        = binary_path
      @config_dir         = nil
      @additional_urls    = []
      @last_out           = ""
      @last_err           = ""
      @last_msg           = ""
    end

    def _wrap_run(work_fn, *args, **kwargs)
      # do some work to extract & merge environment variables if they exist
      has_env = !args.empty? && args[0].instance_of?(Hash)
      env_vars = has_env ? args[0] : {}
      actual_args = has_env ? args[1..-1] : args  # need to shift over if we extracted args
      custom_config = @config_dir.nil? ? [] : ["--config-file", config_file_cli_param.to_s]
      full_args = [binary_path.to_s, "--format", "json"] + custom_config + actual_args
      full_cmd = env_vars.empty? ? full_args : [env_vars] + full_args

      shell_vars = env_vars.map { |k, v| "#{k}=#{v}" }.join(" ")
      @last_msg = " $ #{shell_vars} #{full_args.join(' ')}"
      work_fn.call(*full_cmd, **kwargs)
    end

    # The config file name to be passed on the command line
    #
    # Note https://github.com/arduino/arduino-cli/issues/753 : the --config-file option
    # is really the directory that contains the file
    #
    # @return [Pathname]
    def config_file_path
      @config_dir + CONFIG_FILE_NAME
    end

    # The config file name to be passed on the command line
    #
    # Note https://github.com/arduino/arduino-cli/issues/753 : the --config-file option
    # is really the directory that contains the file
    #
    # @param val [Pathname] The config file that will be used
    # @return [Pathname]
    def config_file_path=(rhs)
      path_rhs = Pathname(rhs)
      err_text = "Config file basename must be '#{CONFIG_FILE_NAME}'. #{CONFIG_FILE_APOLOGY}"
      raise ArgumentError, err_text unless path_rhs.basename.to_s == CONFIG_FILE_NAME

      @config_dir = path_rhs.dirname
    end

    # The config file to be used as a CLI param
    #
    # Apparently Linux wants the whole path, and OSX wants just the directory as of 0.29.0,
    # it's all very annoying.  See unit tests.
    #
    # @return [Pathname] the path to use for a given OS
    def config_file_cli_param
      OS.osx? ? @config_dir : config_file_path
    end

    # Get an acceptable filename for use as a config file
    #
    # Note https://github.com/arduino/arduino-cli/issues/753 : the --config-file option
    # is really the directory that contains the file
    #
    # @param dir [Pathname] the desired directory
    # @return [Pathname]
    def self.config_file_path_from_dir(dir)
      Pathname(dir) + CONFIG_FILE_NAME
    end

    # build and run the arduino command
    def run_and_output(*args, **kwargs)
      _wrap_run((proc { |*a, **k| Host.run_and_output(*a, **k) }), *args, **kwargs)
    end

    # run a command and capture its output
    # @return [Hash] {:out => String, :err => String, :success => bool}
    def run_and_capture(*args, **kwargs)
      ret = _wrap_run((proc { |*a, **k| Host.run_and_capture(*a, **k) }), *args, **kwargs)
      @last_err = ret[:err]
      @last_out = ret[:out]
      ret
    end

    def capture_json(*args, **kwargs)
      ret = run_and_capture(*args, **kwargs)
      ret[:json] = JSON.parse(ret[:out])
      ret
    end

    # Get a dump of the entire config
    # @return [Hash] The configuration
    def config_dump
      capture_json("config", "dump")[:json]
    end

    # @return [String] the path to the Arduino libraries directory
    def lib_dir
      Pathname.new(config_dump["directories"]["user"]) + "libraries"
    end

    # Board manager URLs
    # @return [Array<String>] The additional URLs used by the board manager
    def board_manager_urls
      config_dump["board_manager"]["additional_urls"] + @additional_urls
    end

    # Set board manager URLs
    # @return [Array<String>] The additional URLs used by the board manager
    def board_manager_urls=(all_urls)
      raise ArgumentError("all_urls should be an array, got #{all_urls.class}") unless all_urls.is_a? Array

      @additional_urls = all_urls
    end

    # check whether a board is installed
    # we do this by just selecting a board.
    #   the arduino binary will error if unrecognized and do a successful no-op if it's installed
    # @param boardname [String] The board to test
    # @return [bool] Whether the board is installed
    def board_installed?(boardname)
      run_and_capture("board", "details", "--fqbn", boardname)[:success]
    end

    # check whether a board family is installed (e.g. arduino:avr)
    #
    # @param boardfamily_name [String] The board family to test
    # @return [bool] Whether the board is installed
    def boards_installed?(boardfamily_name)
      capture_json("core", "list")[:json].any? { |b| b["ID"] == boardfamily_name }
    end

    # install a board by name
    # @param name [String] the board name
    # @return [bool] whether the command succeeded
    def install_boards(boardfamily)
      result = if @additional_urls.empty?
        run_and_capture("core", "install", boardfamily)
      else
        run_and_capture("core", "install", boardfamily, "--additional-urls", @additional_urls.join(","))
      end
      result[:success]
    end

    # Find out if a library is available
    #
    # @param name [String] the library name
    # @return [bool] whether the library can be installed via the library manager
    def library_available?(name)
      # the --names flag limits the size of the response to just the name field
      capture_json("lib", "search", "--names", name)[:json]["libraries"].any? { |l| l["name"] == name }
    end

    # @return [Hash] information about installed libraries via the CLI
    def installed_libraries
      capture_json("lib", "list")[:json]
    end

    # @param path [String] The sketch to compile
    # @param boardname [String] The board to use
    # @return [bool] whether the command succeeded
    def compile_sketch(path, boardname)
      ext = File.extname path
      unless ext.casecmp(".ino").zero?
        @last_msg = "Refusing to compile sketch with '#{ext}' extension -- rename it to '.ino'!"
        return false
      end
      unless File.exist? path
        @last_msg = "Can't compile Sketch at nonexistent path '#{path}'!"
        return false
      end
      use_dry_run = should_use_dry_run?
      if use_dry_run
        ret = run_and_capture("compile", "--fqbn", boardname, "--warnings", "all", "--dry-run", path.to_s)
      else
        ret = run_and_capture("compile", "--fqbn", boardname, "--warnings", "all", path.to_s)
      end
      @last_msg = ret[:out]
      ret[:success]
    end

    # Guess the name of a library
    # @param path [Pathname] The path to the library (installed or not)
    # @return [String] the probable library name
    def name_of_library(path)
      src_path = path.realpath
      properties_file = src_path + CppLibrary::LIBRARY_PROPERTIES_FILE
      return src_path.basename.to_s unless properties_file.exist?
      return src_path.basename.to_s if LibraryProperties.new(properties_file).name.nil?

      LibraryProperties.new(properties_file).name
    end

    # Create a handle to an Arduino library by name
    # @param name [String] The library "real name"
    # @return [CppLibrary] The library object
    def library_of_name(name)
      raise ArgumentError, "name is not a String (got #{name.class})" unless name.is_a? String

      CppLibrary.new(name, self)
    end

    # Create a handle to an Arduino library by path
    # @param path [Pathname] The path to the library
    # @return [CppLibrary] The library object
    def library_of_path(path)
      # the path must exist... and if it does, brute-force search the installed libs for it
      realpath = path.realpath  # should produce error if the path doesn't exist to begin with
      entry = installed_libraries.find { |l| Pathname.new(l["library"]["install_dir"]).realpath == realpath }
      probable_name = entry["real_name"].nil? ? realpath.basename.to_s : entry["real_name"]
      CppLibrary.new(probable_name, self)
    end

    # install a library from a path on the local machine (not via library manager), by symlink or no-op as appropriate
    # @param path [Pathname] library to use
    # @return [CppLibrary] the installed library, or nil
    def install_local_library(path)
      src_path         = path.realpath
      library_name     = name_of_library(path)
      cpp_library      = library_of_name(library_name)
      destination_path = cpp_library.path

      # things get weird if the sketchbook contains the library.
      # check that first
      if cpp_library.installed?
        # maybe the project has always lived in the libraries directory, no need to symlink
        return cpp_library if destination_path == src_path

        uhoh = "There is already a library '#{library_name}' in the library directory (#{destination_path})"
        # maybe it's a symlink? that would be OK
        if Host.symlink?(destination_path)
          current_destination_target = Host.readlink(destination_path)
          return cpp_library if current_destination_target == src_path

          @last_msg = "#{uhoh} and it's symlinked to #{current_destination_target} (expected #{src_path})"
          return nil
        end

        @last_msg = "#{uhoh}.  It may need to be removed manually."
        return nil
      end

      # install the library
      libraries_dir = destination_path.parent
      libraries_dir.mkpath unless libraries_dir.exist?
      Host.symlink(src_path, destination_path)
      cpp_library
    end

    # extract the "Free space remaining" amount from the last run
    # @return [Hash] the usage, as a hash with keys :free, :max, and :globals
    def last_bytes_usage
      # Free-spacing syntax for regexes is not working today, not sure why. Make a string and convert to regex.
      re_str = [
        'Global variables use (?<globals>\d+) bytes',
        '\(\d+%\) of dynamic memory,',
        'leaving (?<free>\d+) bytes for local variables.',
        'Maximum is (?<max>\d+) bytes.'
      ].join(" ")
      mem_info = Regexp.new(re_str).match(@last_msg)
      return {} if mem_info.nil?

      Hash[mem_info.names.map(&:to_sym).zip(mem_info.captures.map(&:to_i))]
    end

    def should_use_dry_run?
      ret = capture_json("version")
      version = ret[:json]["VersionString"]
      Gem::Version.new(version) < Gem::Version.new('0.14')
    end
  end
end
