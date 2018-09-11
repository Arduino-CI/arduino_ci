require 'arduino_ci/arduino_cmd'
require 'timeout'

module ArduinoCI

  # Implementation of Arduino linux IDE commands
  class ArduinoCmdLinux < ArduinoCmd

    attr_reader :prefs_response_time

    flag :get_pref,        "--get-pref"
    flag :set_pref,        "--pref"
    flag :save_prefs,      "--save-prefs"
    flag :use_board,       "--board"
    flag :install_boards,  "--install-boards"
    flag :install_library, "--install-library"
    flag :verify,          "--verify"

    def initialize
      super
      @prefs_response_time = nil
    end

    # fetch preferences in their raw form
    # @return [String] Preferences as a set of lines
    def _prefs_raw
      start = Time.now
      resp = run_and_capture(flag_get_pref)
      @prefs_response_time = Time.now - start
      return nil unless resp[:success]

      resp[:out]
    end

    # implementation for Arduino library dir location
    # @return [String] the path to the Arduino libraries directory
    def lib_dir
      File.join(get_pref("sketchbook.path"), "libraries")
    end

    def run_with_gui_guess(message, *args, **kwargs)
      # On Travis CI, we get an error message in the GUI instead of on STDERR
      # so, assume that if we don't get a rapid reply that things are not installed

      prefs if @prefs_response_time.nil?
      x3 = @prefs_response_time * 3
      Timeout.timeout(x3) do
        result = run_and_capture(*args, **kwargs)
        result[:success]
      end
    rescue Timeout::Error
      puts "No response in #{x3} seconds. Assuming graphical modal error message#{message}."
      false
    end

    # underlying preference-setter.
    # @param key [String] the preference key
    # @param value [String] the preference value
    # @return [bool] whether the command succeeded
    def _set_pref(key, value)
      run_with_gui_guess(" about preferences", flag_set_pref, "#{key}=#{value}", flag_save_prefs)
    end

    # check whether a board is installed
    # we do this by just selecting a board.
    #   the arduino binary will error if unrecognized and do a successful no-op if it's installed
    # @param boardname [String] The name of the board
    # @return [bool]
    def board_installed?(boardname)
      run_with_gui_guess(" about board not installed", flag_use_board, boardname)
    end

    # use a particular board for compilation
    # @param boardname [String] The name of the board
    def use_board(boardname)
      run_with_gui_guess(" about board not installed", flag_use_board, boardname, flag_save_prefs)
    end

  end

end
