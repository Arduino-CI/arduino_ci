require 'arduino_ci/display_manager'
require 'arduino_ci/arduino_installation'

module ArduinoCI

  # Wrap the Arduino executable.  This requires, in some cases, a faked display.
  class ArduinoCmd

    class << self
      protected :new

      # @return [ArduinoCmd] A command object with a best guess (or nil) for the installation
      def autolocate
        new(ArduinoInstallation.autolocate)
      end

      # @return [ArduinoCmd] A command object, installing Arduino if necessary
      def autolocate!
        new(ArduinoInstallation.autolocate!)
      end

    end

    attr_accessor :installation
    attr_reader   :prefs_cache
    attr_reader   :prefs_response_time
    attr_reader   :library_is_indexed

    # @param installation [ArduinoInstallation] the location of the Arduino program installation
    def initialize(installation)
      @display_mgr         = DisplayManager::instance
      @installation        = installation
      @prefs_response_time = nil
      @prefs_cache         = prefs
      @library_is_indexed  = false
    end

    # fetch preferences to a hash
    def prefs
      resp = nil
      @display_mgr.with_display do
        start = Time.now
        resp = run_and_capture("--get-pref")
        @prefs_response_time = Time.now - start
      end
      return nil unless resp[:success]
      lines = resp[:out].split("\n").select { |l| l.include? "=" }
      ret = lines.each_with_object({}) do |e, acc|
        parts = e.split("=", 2)
        acc[parts[0]] = parts[1]
        acc
      end
      ret
    end

    # set a preference key/value pair
    # @param key [String] the preference key
    # @param value [String] the preference value
    # @return [bool] whether the command succeeded
    def set_pref(key, value)
      success = run_with_gui_guess(" about preferences", "--pref", "#{key}=#{value}", "--save-prefs")
      @prefs_cache[key] = value if success
      success
    end

    # run the arduino command
    def run(*args, **kwargs)
      full_args = [@installation.cmd_path] + args
      @display_mgr.run(*full_args, **kwargs)
    end

    def run_with_gui_guess(message, *args, **kwargs)
      # On Travis CI, we get an error message in the GUI instead of on STDERR
      # so, assume that if we don't get a rapid reply that things are not installed
      x3 = @prefs_response_time * 3
      Timeout.timeout(x3) do
        result = run_and_capture(*args, **kwargs)
        result[:success]
      end
    rescue Timeout::Error
      puts "No response in #{x3} seconds. Assuming graphical modal error message#{message}."
      false
    end

    # run a command and capture its output
    # @return [Hash] {:out => StringIO, :err => StringIO, :success => bool}
    def run_and_capture(*args)
      pipe_out, pipe_out_wr = IO.pipe
      pipe_err, pipe_err_wr = IO.pipe
      success = run(*args, out: pipe_out_wr, err: pipe_err_wr)
      pipe_out_wr.close
      pipe_err_wr.close
      str_out = pipe_out.read
      str_err = pipe_err.read
      pipe_out.close
      pipe_err.close
      { out: str_out, err: str_err, success: success }
    end

    # check whether a board is installed
    # we do this by just selecting a board.
    #   the arduino binary will error if unrecognized and do a successful no-op if it's installed
    def board_installed?(boardname)
      run_with_gui_guess(" about board not installed", "--board", boardname)
    end

    # install a board by name
    # @param name [String] the board name
    # @return [bool] whether the command succeeded
    def install_board(boardname)
      run_and_capture("--install-boards", boardname)[:success]
    end

    # install a library by name
    # @param name [String] the library name
    # @return [bool] whether the command succeeded
    def install_library(library_name)
      result = run_and_capture("--install-library", library_name)
      @library_is_indexed = true if result[:success]
      result[:success]
    end

    # update the library index
    def update_library_index
      # install random lib so the arduino IDE grabs a new library index
      # see: https://github.com/arduino/Arduino/issues/3535
      install_library("USBHost")
    end

  end
end
