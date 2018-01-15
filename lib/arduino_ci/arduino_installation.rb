require "arduino_ci/host"

DESIRED_ARDUINO_IDE_VERSION = "1.8.5".freeze
USE_BUILDER = false

module ArduinoCI

  # Manage the OS-specific install location of Arduino
  class ArduinoInstallation
    attr_accessor :base_cmd
    attr_accessor :lib_dir
    attr_accessor :requires_x

    class << self
      def force_install_location
        File.join(ENV['HOME'], 'arduino_ci_ide')
      end

      def from_forced_install
        ret = new
        builder = File.join(force_install_location, "arduino-builder")
        if USE_BUILDER && File.exist?(builder)
          ret.base_cmd = [builder]
          ret.requires_x = false
        else
          ret.base_cmd = [File.join(force_install_location, "arduino")]
          ret.requires_x = true
        end
        ret.lib_dir = File.join(force_install_location, "libraries")
        # TODO: "libraries" is what's in the adafruit install.sh script
        ret
      end

      # attempt to find a workable Arduino executable across platforms
      def autolocate
        osx_root = "/Applications/Arduino.app"
        old_way = false
        if File.exist? osx_root
          ret = new
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
          ret.lib_dir = File.join(osx_place, "Libraries")
          ret.requires_x = false
          return ret
        end

        # AAARRRRGGGGHHH
        # Even though arduino-builder is an awesome CLI for Arduino,
        # ALL THE OPTIONS ARE DIFFERENT (single vs double dash for flags)
        #  USELESS FOR THE TIME BEING
        posix_place = Host.which("arduino-builder")
        if USE_BUILDER && !posix_place.nil?
          ret = new
          ret.base_cmd = [posix_place]
          ret.lib_dir = File.join(ENV['HOME'], "Sketchbook") # assume linux
          ret.requires_x = false
          # https://learn.adafruit.com/adafruit-all-about-arduino-libraries-install-use/how-to-install-a-library
          return ret
        end

        posix_place = Host.which("arduino")
        unless posix_place.nil?
          ret = new
          ret.base_cmd = [posix_place]
          ret.lib_dir = File.join(ENV['HOME'], "Sketchbook") # assume linux
          ret.requires_x = true
          # https://learn.adafruit.com/adafruit-all-about-arduino-libraries-install-use/how-to-install-a-library
          return ret
        end

        return from_forced_install if File.exist? force_install_location

        new
      end

      # Attempt to find a workable Arduino executable across platforms, and install it if we don't
      def autolocate!
        candidate = autolocate
        return candidate unless candidate.base_cmd.nil?

        # force the install
        candidate = from_forced_install if force_install
        candidate
      end

      def force_install
        pkgname = "arduino-#{DESIRED_ARDUINO_IDE_VERSION}"
        tarfile = "#{pkgname}-linux64.tar.xz"
        system("wget", "https://downloads.arduino.cc/#{tarfile}")
        system("tar", "xf", tarfile)
        system("mv", pkgname, force_install_location)
      end

    end
  end
end
