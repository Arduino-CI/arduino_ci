require 'arduino_ci/host'
require 'singleton'
require 'timeout'

DESIRED_DISPLAY = ":1.0".freeze

module ArduinoCI

  # When arduino commands run, they need a graphical display.
  # This class handles the setup of that display, if needed.
  class DisplayManager
    include Singleton

    # @return [bool] whether the display manager is currently active
    attr_reader :enabled

    # @return [bool] whether to log messages to the terminal
    attr_accessor :debug

    def initialize
      @existing = existing_display?
      @enabled = false
      @pid = nil
      @debug = false

      # pipes for input and output
      @xv_pipe_out_wr = nil
      @xv_pipe_err_wr = nil
      @xv_pipe_out    = nil
      @xv_pipe_err    = nil
    end

    # attempt to determine if the machine is running a graphical display (i.e. not Travis)
    # @return [bool] whether there is already a GUI that can accept windows
    def existing_display?
      true
    end

    # check whether a process is alive
    # https://stackoverflow.com/a/32513298/2063546
    # @param pid [Int] the process ID
    # @return [bool]
    def alive?(pid)
      Process.kill(0, pid)
      true
    rescue
      false
    end

    # check whether an X server is taking connections
    # @param display [String] the display variable as it would be specified in the environment
    # @return [bool]
    def xserver_exist?(display)
      system({ "DISPLAY" => display }, "xdpyinfo", out: File::NULL, err: File::NULL)
    end

    # wait for the xvfb command to launch
    # @param display [String] the value of the DISPLAY env var
    # @param pid [Int] the process of Xvfb
    # @param timeout [Int] the timeout in seconds
    # @return [Bool] whether we detected a launch
    def xvfb_launched?(display, pid, timeout)
      Timeout.timeout(timeout) do
        loop do
          unless alive? pid
            puts "Xvfb process has died"
            return false
          end
          x = xserver_exist? display
          puts "xdpyinfo reports X server status as #{x}" if debug
          return true if x
          sleep(0.1)
        end
      end
    rescue Timeout::Error
      false
    end

    # enable a virtual display
    def enable
      if @existing
        puts "DisplayManager enable: no-op for what appears to be an existing display" if debug
        @enabled = true
        return
      end

      return unless @pid.nil?  # TODO: disable first?
      @xv_pipe_out.close unless @xv_pipe_out.nil?
      @xv_pipe_err.close unless @xv_pipe_err.nil?

      # open Xvfb
      xvfb_cmd = [
        "Xvfb",
        "+extension", "RANDR",
        ":1",
        "-ac",
        "-screen", "0",
        "1280x1024x16",
      ]
      puts "Xvfb launching" if debug

      @xv_pipe_out, @xv_pipe_out_wr = IO.pipe
      @xv_pipe_err, @xv_pipe_err_wr = IO.pipe
      pipe = IO.popen(xvfb_cmd, stdout: @xv_pipe_out_wr, err: @xv_pipe_err_wr)
      @pid = pipe.pid
      @enabled = xvfb_launched?(DESIRED_DISPLAY, @pid, 30)
    end

    # disable the virtual display
    def disable
      if @existing
        puts "DisplayManager disable: no-op for what appears to be an existing display" if debug
        return @enabled = false
      end

      return @enabled = false if @pid.nil?

      # https://www.whatastruggle.com/timeout-a-subprocess-in-ruby
      begin
        Timeout.timeout(30) do
          Process.kill("TERM", @pid)
          puts "Xvfb TERMed" if debug
        end
      rescue Timeout::Error
        Process.kill(9, @pid)
        puts "Xvfb KILLed" if debug
      ensure
        Process.wait @pid
        @enabled = false
        @pid = nil

        @xv_pipe_out_wr.close
        @xv_pipe_err_wr.close
      end
    end

    # Enable a virtual display for the duration of the given block
    # @yield [environment] The code to execute within the display environment
    # @yieldparam [Hash] the environment variables relating to the display
    def with_display
      was_enabled = @enabled
      enable unless was_enabled
      begin
        yield environment
      ensure
        disable unless was_enabled
      end
    end

    def wrap_run(work_fn, *args, **kwargs)
      ret = nil
      # do some work to extract & merge environment variables if they exist
      has_env = !args.empty? && args[0].class == Hash
      with_display do |env_vars|
        env_vars = {} if env_vars.nil?
        env_vars.merge!(args[0]) if has_env
        actual_args = has_env ? args[1..-1] : args  # need to shift over if we extracted args
        full_cmd = env_vars.empty? ? actual_args : [env_vars] + actual_args
        ret = work_fn.call(*full_cmd, **kwargs)
      end
      ret
    end

    # run a command in a display, outputting to stdout
    # @return [bool]
    def run_and_output(*args, **kwargs)
      wrap_run((proc { |*a, **k| Host.run_and_output(*a, **k) }), *args, **kwargs)
    end

    # run a command in a display, capturing output
    # @return [bool]
    def run_and_capture(*args, **kwargs)
      wrap_run((proc { |*a, **k| Host.run_and_capture(*a, **k) }), *args, **kwargs)
    end

    # @return [Hash] the environment variables for the display
    def environment
      return nil unless @existing || @enabled
      return { "EXISTING_DISPLAY" => "YES" } if @existing
      { "DISPLAY" => DESIRED_DISPLAY }
    end

    # On finalize, ensure child process is ended
    def self.finalize
      disable
    end
  end
end
