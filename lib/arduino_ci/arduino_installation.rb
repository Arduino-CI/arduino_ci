require 'pathname'
require "arduino_ci/host"
require "arduino_ci/arduino_cmd_osx"
require "arduino_ci/arduino_cmd_linux"
require "arduino_ci/arduino_cmd_windows"
require "arduino_ci/arduino_cmd_linux_builder"
require "arduino_ci/arduino_downloader_osx"
require "arduino_ci/arduino_downloader_linux"

require "arduino_ci/arduino_downloader_windows" if ArduinoCI::Host.os == :windows

DESIRED_ARDUINO_IDE_VERSION = "1.8.6".freeze

module ArduinoCI

  class ArduinoInstallationError < StandardError; end

  # Manage the OS-specific install location of Arduino
  class ArduinoInstallation

    class << self

      # attempt to find a workable Arduino executable across platforms
      #
      # Autolocation assumed to be an expensive operation
      # @return [ArduinoCI::ArduinoCmd] an instance of the command or nil if it can't be found
      def autolocate
        ret = nil
        case Host.os
        when :osx then
          ret = autolocate_osx
        when :linux then
          loc = ArduinoDownloaderLinux.autolocated_executable
          return nil if loc.nil?

          ret = ArduinoCmdLinux.new
          ret.base_cmd = [loc]
          ret.binary_path = Pathname.new(loc)
        when :windows then
          loc = ArduinoDownloaderWindows.autolocated_executable
          return nil if loc.nil?

          ret = ArduinoCmdWindows.new
          ret.base_cmd = [loc]
          ret.binary_path = Pathname.new(loc)
        end
        ret
      end

      # @return [ArduinoCI::ArduinoCmdOSX] an instance of the command or nil if it can't be found
      def autolocate_osx
        osx_root = ArduinoDownloaderOSX.autolocated_installation
        return nil if osx_root.nil?
        return nil unless File.exist? osx_root

        launchers = [
          # try a hack that skips splash screen
          # from https://github.com/arduino/Arduino/issues/1970#issuecomment-321975809
          [
            "java",
            "-cp",
            "#{osx_root}/Contents/Java/*",
            "-DAPP_DIR=#{osx_root}/Contents/Java",
            "-Dfile.encoding=UTF-8",
            "-Dapple.awt.UIElement=true",
            "-Xms128M",
            "-Xmx512M",
            "processing.app.Base",
          ],
          # failsafe way
          [File.join(osx_root, "Contents", "MacOS", "Arduino")]
        ]

        # create return and find a command launcher that works
        ret = ArduinoCmdOSX.new
        launchers.each do |launcher|
          # test whether this method successfully launches the IDE
          # note that "successful launch" involves a command that will fail,
          # because that's faster than any command which succeeds.  what we
          # don't want to see is a java error.
          args = launcher + ["--bogus-option"]
          result = Host.run_and_capture(*args)
          next unless result[:err].include? "Error: unknown option: --bogus-option"

          ret.base_cmd = launcher
          ret.binary_path = Pathname.new(osx_root)
          return ret
        end
        nil
      end

      # Attempt to find a workable Arduino executable across platforms, and install it if we don't
      # @return [ArduinoCI::ArduinoCmd] an instance of a command
      def autolocate!
        candidate = autolocate
        return candidate unless candidate.nil?

        # force the install
        raise ArduinoInstallationError, "Failed to force-install Arduino" unless force_install

        autolocate
      end

      # Forcibly install Arduino from the web
      # @return [bool] Whether the command succeeded
      def force_install
        worker_class =  case Host.os
                        when :osx then ArduinoDownloaderOSX
                        when :windows then ArduinoDownloaderWindows
                        when :linux then ArduinoDownloaderLinux
                        end
        worker = worker_class.new(DESIRED_ARDUINO_IDE_VERSION)
        worker.execute
      end

    end
  end
end
