require 'singleton'

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
      return true if RUBY_PLATFORM.include? "darwin"
      return true if ENV["DISPLAY"].nil?
      return true if ENV["DISPLAY"].include? ":"
      false
    end

    # enable a virtual display
    def enable
      return @enabled = true if @existing   # silent no-op if built in display
      return unless @pid.nil?

      @enabled = true
      @pid = fork do
        puts "Forking Xvfb"
        system("Xvfb", ":1", "-ac", "-screen", "0", "1280x1024x16")
        puts "Xvfb unexpectedly quit!"
      end
      sleep(3)  # TODO: test a connection to the X server?
    end

    # disable the virtual display
    def disable
      return @enabled = false if @existing  # silent no-op if built in display
      return if @pid.nil?

      begin
        Process.kill 9, @pid
      ensure
        Process.wait @pid
        @pid = nil
      end
      puts "Xvfb killed"
    end

    # Enable a virtual display for the duration of the given block
    def with_display
      enable
      begin
        yield environment
      ensure
        disable
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
