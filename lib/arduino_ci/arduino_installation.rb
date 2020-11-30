require 'pathname'
require "arduino_ci/host"
require "arduino_ci/arduino_backend"
require "arduino_ci/arduino_downloader_osx"
require "arduino_ci/arduino_downloader_linux"
require "arduino_ci/arduino_downloader_windows" if ArduinoCI::Host.os == :windows

module ArduinoCI

  class ArduinoInstallationError < StandardError; end

  # Manage the OS-specific install location of Arduino
  class ArduinoInstallation

    DESIRED_ARDUINO_CLI_VERSION = "0.13.0".freeze

    class << self

      # attempt to find a workable Arduino executable across platforms
      #
      # Autolocation assumed to be an expensive operation
      # @return [ArduinoCI::ArduinoBackend] an instance of the command or nil if it can't be found
      def autolocate
        downloader_class = case Host.os
        when :osx     then ArduinoDownloaderOSX
        when :linux   then ArduinoDownloaderLinux
        when :windows then ArduinoDownloaderWindows
        end

        loc = downloader_class.autolocated_executable
        return nil if loc.nil?

        ArduinoBackend.new(loc)
      end

      # Attempt to find a workable Arduino executable across platforms, and install it if we don't
      # @return [ArduinoCI::ArduinoBackend] an instance of a command
      def autolocate!(output = $stdout)
        candidate = autolocate
        return candidate unless candidate.nil?

        # force the install
        raise ArduinoInstallationError, "Failed to force-install Arduino" unless force_install(output)

        autolocate
      end

      # Forcibly install Arduino from the web
      # @return [bool] Whether the command succeeded
      def force_install(output = $stdout, version = DESIRED_ARDUINO_CLI_VERSION)
        worker_class = case Host.os
        when :osx then ArduinoDownloaderOSX
        when :windows then ArduinoDownloaderWindows
        when :linux then ArduinoDownloaderLinux
        end
        worker = worker_class.new(version, output)
        worker.execute
      end

    end
  end
end
