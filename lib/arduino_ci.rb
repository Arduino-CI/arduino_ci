require "arduino_ci/version"

require 'singleton'

# Cross-platform way of finding an executable in the $PATH.
# via https://stackoverflow.com/a/5471032/2063546
#   which('ruby') #=> /usr/bin/ruby
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

# ArduinoCI contains classes for automated testing of Arduino code on the command line
# @author Ian Katz <ifreecarve@gmail.com>
module ArduinoCI

  # Wrap the Arduino executable.  This requires, in some cases, a faked display.
  class ArduinoCmd

    # create as many ArduinoCmds as you like, but we need one and only one display manager
    class DisplayMgr
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

    class << self
      protected :new

      # attempt to find a workable Arduino executable across platforms
      def guess_executable_location
        osx_place = "/Applications/Arduino.app/Contents/MacOS/Arduino"
        places = {
          "arduino" => !which("arduino").nil?,
          osx_place => (File.exist? osx_place),
        }
        places.each { |k, v| return k if v }
        nil
      end

      def autolocate
        ret = new
        ret.path = guess_executable_location
        ret
      end
    end

    attr_accessor :path

    def initialize
      @display_mgr = DisplayMgr::instance
    end

  end

end
