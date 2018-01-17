require "arduino_ci/host"
require "arduino_ci/arduino_cmd_osx"
require "arduino_ci/arduino_cmd_linux"

DESIRED_ARDUINO_IDE_VERSION = "1.8.5".freeze
USE_BUILDER = false

module ArduinoCI

  # Manage the OS-specific install location of Arduino
  class ArduinoInstallation

    class << self
      def force_install_location
        File.join(ENV['HOME'], 'arduino_ci_ide')
      end

      # attempt to find a workable Arduino executable across platforms
      def autolocate
        case Host.os
        when :osx then autolocate_osx
        when :linux then autolocate_linux
        end
      end

      def autolocate_osx
        osx_root = "/Applications/Arduino.app"
        old_way = false
        return nil unless File.exist? osx_root

        ret = ArduinoCmdOSX.new
        osx_place = "#{osx_root}/Contents/MacOS"

        if old_way
          ret.base_cmd = [File.join(osx_place, "Arduino")]
        else
          jvm_runtime = `/usr/libexec/java_home`
          ret.base_cmd = [
            "java",
            "-cp", "#{osx_root}/Contents/Java/*",
            "-DAPP_DIR=#{osx_root}/Contents/Java",
            "-Djava.ext.dirs=$JVM_RUNTIME/Contents/Home/lib/ext/:#{jvm_runtime}/Contents/Home/jre/lib/ext/",
            "-Dfile.encoding=UTF-8",
            "-Dapple.awt.UIElement=true",
            "-Xms128M",
            "-Xmx512M",
            "processing.app.Base",
          ]
        end
        ret
      end

      def autolocate_linux
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
      def autolocate!
        candidate = autolocate
        return candidate unless candidate.nil?

        # force the install
        force_install
        autolocate
      end

      def force_install
        case Host.os
        when :linux
          pkgname = "arduino-#{DESIRED_ARDUINO_IDE_VERSION}"
          tarfile = "#{pkgname}-linux64.tar.xz"
          if File.exist? tarfile
            puts "Arduino tarfile seems to have been downloaded already"
          else
            puts "Downloading Arduino binary with wget"
            system("wget", "https://downloads.arduino.cc/#{tarfile}")
          end

          if File.exist? pkgname
            puts "Tarfile seems to have been extracted already"
          else
            puts "Extracting archive with tar"
            system("tar", "xf", tarfile)
          end

          if File.exist? force_install_location
            puts "Arduino binary seems to have already been force-installed"
          else
            system("mv", pkgname, force_install_location)
          end
        end
      end

    end
  end
end
