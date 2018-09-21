require 'fileutils'
require 'pathname'

# workaround for https://github.com/arduino/Arduino/issues/3535
WORKAROUND_LIB = "USBHost".freeze

module ArduinoCI

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

    # the array of command components to launch the Arduino executable
    # @return [Array<String>]
    attr_accessor :base_cmd

    # the actual path to the executable on this platform
    # @return [Pathname]
    attr_accessor :binary_path

    # part of a workaround for https://github.com/arduino/Arduino/issues/3535
    attr_reader   :libraries_indexed

    # @return [String] STDOUT of the most recently-run command
    attr_reader   :last_out

    # @return [String] STDERR of the most recently-run command
    attr_reader   :last_err

    # @return [String] the most recently-run command
    attr_reader   :last_msg

    # set the command line flags (undefined for now).
    # These vary between gui/cli
    flag :get_pref
    flag :set_pref
    flag :save_prefs
    flag :use_board
    flag :install_boards
    flag :install_library
    flag :verify

    def initialize
      @prefs_cache        = {}
      @prefs_fetched      = false
      @libraries_indexed  = false
      @last_out           = ""
      @last_err           = ""
      @last_msg           = ""
    end

    # Convert a preferences dump into a flat hash
    # @param arduino_output [String] The raw Arduino executable output
    # @return [Hash] preferences as a hash
    def parse_pref_string(arduino_output)
      lines = arduino_output.split("\n").select { |l| l.include? "=" }
      ret = lines.each_with_object({}) do |e, acc|
        parts = e.split("=", 2)
        acc[parts[0]] = parts[1]
        acc
      end
      ret
    end

    # @return [String] the path to the Arduino libraries directory
    def lib_dir
      Pathname.new(get_pref("sketchbook.path")) + "libraries"
    end

    # fetch preferences in their raw form
    # @return [String] Preferences as a set of lines
    def _prefs_raw
      resp = run_and_capture(flag_get_pref)
      return nil unless resp[:success]

      @prefs_fetched = true
      resp[:out]
    end

    # Get the Arduino preferences, from cache if possible
    # @return [Hash] The full set of preferences
    def prefs
      prefs_raw = _prefs_raw unless @prefs_fetched
      return nil if prefs_raw.nil?

      @prefs_cache = parse_pref_string(prefs_raw)
      @prefs_cache.clone
    end

    # get a preference key
    # @param key [String] The preferences key to look up
    # @return [String] The preference value
    def get_pref(key)
      data = @prefs_fetched ? @prefs_cache : prefs
      data[key]
    end

    # underlying preference-setter.
    # @param key [String] The preference name
    # @param value [String] The value to set to
    # @return [bool] whether the command succeeded
    def _set_pref(key, value)
      run_and_capture(flag_set_pref, "#{key}=#{value}", flag_save_prefs)[:success]
    end

    # set a preference key/value pair, and update the cache.
    # @param key [String] the preference key
    # @param value [String] the preference value
    # @return [bool] whether the command succeeded
    def set_pref(key, value)
      prefs unless @prefs_fetched  # update cache first
      success = _set_pref(key, value)
      @prefs_cache[key] = value if success
      success
    end

    def _wrap_run(work_fn, *args, **kwargs)
      # do some work to extract & merge environment variables if they exist
      has_env = !args.empty? && args[0].class == Hash
      env_vars = has_env ? args[0] : {}
      actual_args = has_env ? args[1..-1] : args  # need to shift over if we extracted args
      full_args = @base_cmd + actual_args
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

    # Board manager URLs
    # @return [Array<String>] The additional URLs used by the board manager
    def board_manager_urls
      url_list = get_pref("boardsmanager.additional.urls")
      return [] if url_list.nil?

      url_list.split(",")
    end

    # Set board manager URLs
    # @return [Array<String>] The additional URLs used by the board manager
    def board_manager_urls=(all_urls)
      set_pref("boardsmanager.additional.urls", all_urls.join(","))
    end

    # check whether a board is installed
    # we do this by just selecting a board.
    #   the arduino binary will error if unrecognized and do a successful no-op if it's installed
    # @param boardname [String] The board to test
    # @return [bool] Whether the board is installed
    def board_installed?(boardname)
      run_and_capture(flag_use_board, boardname)[:success]
    end

    # install a board by name
    # @param name [String] the board name
    # @return [bool] whether the command succeeded
    def install_boards(boardfamily)
      # TODO: find out why IO.pipe fails but File::NULL succeeds :(
      result = run_and_capture(flag_install_boards, boardfamily)
      already_installed = result[:err].include?("Platform is already installed!")
      result[:success] || already_installed
    end

    # install a library by name
    # @param name [String] the library name
    # @return [bool] whether the command succeeded
    def _install_library(library_name)
      success = run_and_capture(flag_install_library, library_name)[:success]

      @libraries_indexed = (@libraries_indexed || success) if library_name == WORKAROUND_LIB
      success
    end

    # index the set of libraries by installing a dummy library
    # related to WORKAROUND_LIB and https://github.com/arduino/Arduino/issues/3535
    # TODO: unclear if this is still necessary
    def index_libraries
      return true if @libraries_indexed

      _install_library(WORKAROUND_LIB)
      @libraries_indexed
    end

    # install a library by name
    # @param name [String] the library name
    # @return [bool] whether the command succeeded
    def install_library(library_name)
      index_libraries
      _install_library(library_name)
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

    # update the library index
    # @return [bool] Whether the update succeeded
    def update_library_index
      # install random lib so the arduino IDE grabs a new library index
      # see: https://github.com/arduino/Arduino/issues/3535
      install_library("USBHost")
    end

    # use a particular board for compilation
    # @param boardname [String] The board to use
    # @return [bool] whether the command succeeded
    def use_board(boardname)
      run_and_capture(flag_use_board, boardname, flag_save_prefs)[:success]
    end

    # use a particular board for compilation, installing it if necessary
    # @param boardname [String] The board to use
    # @return [bool] whether the command succeeded
    def use_board!(boardname)
      return true if use_board(boardname)

      boardfamily = boardname.split(":")[0..1].join(":")
      puts "Board '#{boardname}' not found; attempting to install '#{boardfamily}'"
      return false unless install_boards(boardfamily) # guess board family from first 2 :-separated fields

      use_board(boardname)
    end

    # @param path [String] The sketch to verify
    # @return [bool] whether the command succeeded
    def verify_sketch(path)
      ext = File.extname path
      unless ext.casecmp(".ino").zero?
        @last_msg = "Refusing to verify sketch with '#{ext}' extension -- rename it to '.ino'!"
        return false
      end
      unless File.exist? path
        @last_msg = "Can't verify Sketch at nonexistent path '#{path}'!"
        return false
      end
      ret = run_and_capture(flag_verify, path)
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
      files.reject(&:nil?)
    end
  end
end
