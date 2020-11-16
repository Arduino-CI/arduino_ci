require 'fileutils'
require 'pathname'
require 'json'

# workaround for https://github.com/arduino/Arduino/issues/3535
WORKAROUND_LIB = "USBHost".freeze

module ArduinoCI

  # To report errors that we can't resolve or possibly even explain
  class ArduinoExecutionError < StandardError; end

  # Wrap the Arduino executable.  This requires, in some cases, a faked display.
  class ArduinoCmd

    # Enable a shortcut syntax for command line flags
    # @param name [String] What the flag will be called (prefixed with 'flag_')
    # @return [void]
    # @macro [attach] flag
    #   The text of the command line flag for $1
    #   @!attribute [r] flag_$1
    #   @return [String] the text of the command line flag (`$2` in this case)
    def self.flag(name, text = nil)
      text = "(flag #{name} not defined)" if text.nil?
      self.class_eval("def flag_#{name};\"#{text}\";end", __FILE__, __LINE__)
    end

    # the actual path to the executable on this platform
    # @return [Pathname]
    attr_accessor :binary_path

    # @return [String] STDOUT of the most recently-run command
    attr_reader   :last_out

    # @return [String] STDERR of the most recently-run command
    attr_reader   :last_err

    # @return [String] the most recently-run command
    attr_reader   :last_msg

    # @return [Array<String>] Additional URLs for the boards manager
    attr_reader   :additional_urls

    # set the command line flags (undefined for now).
    # These vary between gui/cli.  Inline comments added for greppability
    flag :install_boards     # flag_install_boards
    flag :install_library    # flag_install_library
    flag :verify             # flag_verify

    def initialize(binary_path)
      @binary_path        = binary_path
      @additional_urls    = []
      @last_out           = ""
      @last_err           = ""
      @last_msg           = ""
    end

    def _wrap_run(work_fn, *args, **kwargs)
      # do some work to extract & merge environment variables if they exist
      has_env = !args.empty? && args[0].class == Hash
      env_vars = has_env ? args[0] : {}
      actual_args = has_env ? args[1..-1] : args  # need to shift over if we extracted args
      full_args = [binary_path.to_s, "--format", "json"] + actual_args
      full_cmd = env_vars.empty? ? full_args : [env_vars] + full_args

      shell_vars = env_vars.map { |k, v| "#{k}=#{v}" }.join(" ")
      @last_msg = " $ #{shell_vars} #{full_args.join(' ')}"
      work_fn.call(*full_cmd, **kwargs)
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
    end

    # Get a dump of the entire config
    # @return [Hash] The configuration
    def config_dump
      capture_json("config", "dump")
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
      # capture_json("core", "list")[:json].find { |b| b["ID"] == boardname } # nope, this is for the family
      run_and_capture("board", "details", "--fqbn", boardname)[:success]
    end

    # install a board by name
    # @param name [String] the board name
    # @return [bool] whether the command succeeded
    def install_boards(boardfamily)
      result = run_and_capture("core", "install", boardfamily)
      result[:success]
    end

    # @return [Hash] information about installed libraries via the CLI
    def installed_libraries
      capture_json("lib", "list")[:json]
    end

    # install a library by name
    # @param name [String] the library name
    # @param version [String] the version to install
    # @return [bool] whether the command succeeded
    def install_library(library_name, version = nil)
      return true if library_present?(library_name)

      fqln = version.nil? ? library_name : "#{library_name}@#{version}"
      result = run_and_capture("lib", "install", fqln)
      result[:success]
    end

    # generate the (very likely) path of a library given its name
    # @param library_name [String] The name of the library
    # @return [Pathname] The fully qualified library name
    def library_path(library_name)
      Pathname.new(lib_dir) + library_name
    end

    # Determine whether a library is present in the lib dir
    #
    # Note that `true` doesn't guarantee that the library is valid/installed
    #  and `false` doesn't guarantee that the library isn't built-in
    #
    # @param library_name [String] The name of the library
    # @return [bool]
    def library_present?(library_name)
      library_path(library_name).exist?
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
      ret = run_and_capture("compile", "--fqbn", boardname, "--warnings", "all", "--dry-run", path)
      ret[:success]
    end

    # ensure that the given library is installed, or symlinked as appropriate
    # return the path of the prepared library, or nil
    # @param path [Pathname] library to use
    # @return [String] the path of the installed library
    def install_local_library(path)
      src_path = path.realpath
      library_name = src_path.basename
      destination_path = library_path(library_name)

      # things get weird if the sketchbook contains the library.
      # check that first
      if destination_path.exist?
        uhoh = "There is already a library '#{library_name}' in the library directory"
        return destination_path if destination_path == src_path

        # maybe it's a symlink? that would be OK
        if destination_path.symlink?
          return destination_path if destination_path.readlink == src_path

          @last_msg = "#{uhoh} and it's not symlinked to #{src_path}"
          return nil
        end

        @last_msg = "#{uhoh}.  It may need to be removed manually."
        return nil
      end

      # install the library
      Host.symlink(src_path, destination_path)
      destination_path
    end

    # @param installed_library_path [String] The library to query
    # @return [Array<String>] Example sketch files
    def library_examples(installed_library_path)
      example_path = Pathname.new(installed_library_path) + "examples"
      return [] unless File.exist?(example_path)

      examples = example_path.children.select(&:directory?).map(&:to_path).map(&File.method(:basename))
      files = examples.map do |e|
        proj_file = example_path + e + "#{e}.ino"
        proj_file.exist? ? proj_file.to_s : nil
      end
      files.reject(&:nil?).sort_by(&:to_s)
    end
  end
end
