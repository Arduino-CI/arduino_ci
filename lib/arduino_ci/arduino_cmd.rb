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

    # @param installation [ArduinoInstallation] the location of the Arduino program installation
    def initialize(installation)
      @display_mgr = DisplayManager::instance
      @installation = installation
    end

    # run the arduino command
    def run(*args)
      full_args = [@installation.cmd_path] + args
      @display_mgr.run(*full_args)
    end

    def board_installed?(board)
      run("--board", board)
    end

  end
end
