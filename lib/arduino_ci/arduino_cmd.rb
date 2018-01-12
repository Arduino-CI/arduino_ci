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

    # @param installation [ArduinoInstallation] the location of the Arduino program installation
    def initialize(installation)
      @display_mgr         = DisplayManager::instance
      @installation        = installation
      @prefs_response_time = nil
      @prefs_cache         = prefs
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
    # @return [Hash] {:out => StringIO, :err => StringIO }
    def run(*args, **kwargs)
      full_args = [@installation.cmd_path] + args
      @display_mgr.run(*full_args, **kwargs)
    end

    def run_with_gui_guess(message, *args, **kwargs)
      # On Travis CI, we get an error message in the GUI instead of on STDERR
      # so, assume that if we don't get a rapid reply that things are not installed
      x3 = @prefs_response_time * 3
      Timeout.timeout(x3) do
        run(*args, **kwargs)
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

    def board_installed?(board)
      # On Travis CI, we get an error message in the GUI instead of on STDERR
      # so, assume that if we don't get a rapid reply that things are not installed
      x3 = @prefs_response_time * 3
      Timeout.timeout(x3) do
        run("--board", board)
      end
    rescue Timeout::Error
      puts "No response in #{x3} seconds. Assuming graphical modal error message about board not installed."
      false
    end

  end
end
