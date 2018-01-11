require 'arduino_ci/display_manager'
require 'arduino_ci/arduino_installation'

module ArduinoCI

  # Wrap the Arduino executable.  This requires, in some cases, a faked display.
  class ArduinoCmd

    class << self
      protected :new

      def autolocate
        new(ArduinoInstallation.autolocate)
      end

      def autolocate!
        new(ArduinoInstallation.autolocate!)
      end

    end

    attr_accessor :installation

    def initialize(installation)
      @display_mgr = DisplayManager::instance
      @installation = installation
    end

    def run(*args)
      full_args = [@display_mgr.environment, @installation.cmd_path] + args
      puts "Running $ #{full_args.join(' ')}"
      system(*full_args)
    end

    def board_installed?(board)
      run("--board", board)
    end

  end
end
