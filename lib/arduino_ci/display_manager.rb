require 'arduino_ci/host'
require 'singleton'
require 'timeout'

DESIRED_DISPLAY = ":1.0".freeze

module ArduinoCI

  # When arduino commands run, they need a graphical display.
  # This class handles the setup of that display, if needed.
  class DisplayManager
    include Singleton
    attr_reader :enabled

    def initialize
      @existing = existing_display?
      @enabled = false
      @pid = nil

      @xv_pipe_out_wr = nil
      @xv_pipe_err_wr = nil
      @xv_pipe_out    = nil
      @xv_pipe_err    = nil
    end

    # attempt to determine if the machine is running a graphical display (i.e. not Travis)
    def existing_display?
      return true  if RUBY_PLATFORM.include? "darwin"
      return false if ENV["DISPLAY"].nil?
      return true  if ENV["DISPLAY"].include? ":"
      false
    end

    # check whether a process is alive
    # https://stackoverflow.com/a/32513298/2063546
    def alive?(pid)
      Process.kill(0, pid)
      true
    rescue
      false
    end

    # check whether an X server is taking connections
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
          puts "xdpyinfo reports X server status as #{x}"
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
        puts "DisplayManager enable: no-op for what appears to be an existing display"
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
      puts "Xvfb launching"

      @xv_pipe_out, @xv_pipe_out_wr = IO.pipe
      @xv_pipe_err, @xv_pipe_err_wr = IO.pipe
      pipe = IO.popen(xvfb_cmd, stdout: @xv_pipe_out_wr, err: @xv_pipe_err_wr)
      @pid = pipe.pid
      @enabled = xvfb_launched?(DESIRED_DISPLAY, @pid, 30)
    end

    # disable the virtual display
    def disable
      if @existing
        puts "DisplayManager disable: no-op for what appears to be an existing display"
        return @enabled = false
      end

      return @enabled = false if @pid.nil?

      # https://www.whatastruggle.com/timeout-a-subprocess-in-ruby
      begin
        Timeout.timeout(30) do
          Process.kill("TERM", @pid)
          puts "Xvfb TERMed"
        end
      rescue Timeout::Error
        Process.kill(9, @pid)
        puts "Xvfb KILLed"
      ensure
        Process.wait @pid
        @enabled = false
        @pid = nil

        @xv_pipe_out_wr.close
        @xv_pipe_err_wr.close
      end
    end

    # Enable a virtual display for the duration of the given block
    def with_display
      was_enabled = @enabled
      enable unless was_enabled
      begin
        yield environment
      ensure
        disable unless was_enabled
      end
    end

    # run a command in a display
    def run(*args, **kwargs)
      ret = false
      # do some work to extract & merge environment variables if they exist
      has_env = !args.empty? && args[0].class == Hash
      with_display do |env_vars|
        env_vars = {} if env_vars.nil?
        env_vars.merge!(args[0]) if has_env
        actual_args = has_env ? args[1..-1] : args  # need to shift over if we extracted args
        full_cmd = env_vars.empty? ? actual_args : [env_vars] + actual_args
        shell_vars = env_vars.map { |k, v| "#{k}=#{v}" }.join(" ")
        puts " $ #{shell_vars} #{actual_args.join(' ')}"
        ret = system(*full_cmd, **kwargs)
        puts "#{actual_args[0]} has completed"
      end
      ret
    end

    # run a command in a display with no output
    def run_silent(*args)
      run(*args, out: File::NULL, err: File::NULL)
    end

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
