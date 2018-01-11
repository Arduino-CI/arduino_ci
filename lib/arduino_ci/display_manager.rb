require 'arduino_ci/host'
require 'singleton'
require 'timeout'

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
    end

    # attempt to determine if the machine is running a graphical display (i.e. not Travis)
    def existing_display?
      return true  if RUBY_PLATFORM.include? "darwin"
      return false if ENV["DISPLAY"].nil?
      return true  if ENV["DISPLAY"].include? ":"
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

      @enabled = true
      # open Xvfb
      xvfb_cmd = ["Xvfb", ":1", "-ac", "-screen", "0", "1280x1024x16"]
      puts "pipeline_start for Xvfb"
      pipe = IO.popen(xvfb_cmd)
      @pid = pipe.pid
      sleep(3)  # TODO: test a connection to the X server?
    end

    # disable the virtual display
    def disable
      if @existing
        puts "DisplayManager disable: no-op for what appears to be an existing display"
        @enabled = true
        return
      end

      return if @pid.nil?

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

    def environment
      return nil unless @existing || @enabled
      return {} if @existing
      { DISPLAY => ":1.0" }
    end

    # On finalize, ensure child process is ended
    def self.finalize
      disable
    end
  end
end
