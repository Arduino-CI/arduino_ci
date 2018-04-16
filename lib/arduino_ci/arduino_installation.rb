require "arduino_ci/host"
require "arduino_ci/arduino_cmd_osx"
require "arduino_ci/arduino_cmd_linux"
require "arduino_ci/arduino_cmd_linux_builder"

DESIRED_ARDUINO_IDE_VERSION = "1.8.5".freeze
USE_BUILDER = false
DOWNLOAD_ATTEMPTS = 3

module ArduinoCI

  # Manage the OS-specific install location of Arduino
  class ArduinoInstallation

    class << self
      # @return [String] The location where a forced install will go
      def force_install_location
        File.join(ENV['HOME'], 'arduino_ci_ide')
      end

      # attempt to find a workable Arduino executable across platforms
      # @return [ArduinoCI::ArduinoCmd] an instance of the command
      def autolocate
        case Host.os
        when :osx then autolocate_osx
        when :linux then autolocate_linux
        end
      end

      # @return [ArduinoCI::ArduinoCmdOSX] an instance of a command
      def autolocate_osx
        osx_root = "/Applications/Arduino.app/Contents"
        return nil unless File.exist? osx_root

        ret = ArduinoCmdOSX.new

        # old_way
        # ret.base_cmd = [File.join("#{osx_root}/MacOS", "Arduino")]
        ret.base_cmd = [
          "java",
          "-cp", "#{osx_root}/Java/*",
          "-DAPP_DIR=#{osx_root}/Java",
          "-Dfile.encoding=UTF-8",
          "-Dapple.awt.UIElement=true",
          "-Xms128M",
          "-Xmx512M",
          "processing.app.Base",
        ]
        ret
      end

      # @return [ArduinoCI::ArduinoCmdLinux] an instance of a command
      def autolocate_linux
        if USE_BUILDER
          builder_name = "arduino-builder"
          cli_place = Host.which(builder_name)
          unless cli_place.nil?
            ret = ArduinoCmdLinuxBuilder.new
            ret.base_cmd = [cli_place]
            return ret
          end

          forced_builder = File.join(force_install_location, builder_name)
          if File.exist?(forced_builder)
            ret = ArduinoCmdLinuxBuilder.new
            ret.base_cmd = [forced_builder]
            return ret
          end
        end

        gui_name = "arduino"
        gui_place = Host.which(gui_name)
        unless gui_place.nil?
          ret = ArduinoCmdLinux.new
          ret.base_cmd = [gui_place]
          return ret
        end

        forced_arduino = File.join(force_install_location, gui_name)
        if File.exist?(forced_arduino)
          ret = ArduinoCmdLinux.new
          ret.base_cmd = [forced_arduino]
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
        force_install
        autolocate
      end

      # Forcibly install Arduino from the web
      # @return [bool] Whether the command succeeded
      def force_install
        case Host.os
        when :linux
          pkgname = "arduino-#{DESIRED_ARDUINO_IDE_VERSION}"
          tarfile = "#{pkgname}-linux64.tar.xz"
          url = "https://downloads.arduino.cc/#{tarfile}"
          attempts = 0

          unless Host.which("wget")
            puts "Arduino force-install failed: wget does not appear to be installed!"
            return
          end

          loop do
            if File.exist? tarfile
              puts "Arduino tarfile seems to have been downloaded already" if attempts.zero?
              break
            elsif attempts >= DOWNLOAD_ATTEMPTS
              break puts "After #{DOWNLOAD_ATTEMPTS} attempts, failed to download #{url}"
            else
              puts "Attempting to download Arduino binary with wget"
              system("wget", "--quiet", "--progress=dot:giga", url)
            end
            attempts += 1
          end

          if File.exist? pkgname
            puts "Tarfile seems to have been extracted already"
          elsif File.exist? tarfile
            puts "Extracting archive with tar"
            system("tar", "xf", tarfile)
          end

          if File.exist? force_install_location
            puts "Arduino binary seems to have already been force-installed"
          elsif File.exist? pkgname
            system("mv", pkgname, force_install_location)
          else
            puts "Arduino force-install failed"
          end
        end
      end

    end
  end
end
