require "arduino_ci/host"

DESIRED_ARDUINO_IDE_VERSION = "1.8.5".freeze

module ArduinoCI

  # Manage the OS-specific install location of Arduino
  class ArduinoInstallation
    attr_accessor :cmd_path
    attr_accessor :lib_dir

    class << self
      def force_install_location
        File.join(ENV['HOME'], 'arduino_ci_ide')
      end

      # attempt to find a workable Arduino executable across platforms
      def autolocate
        ret = new

        osx_place = "/Applications/Arduino.app/Contents/MacOS"
        if File.exist? osx_place
          ret.cmd_path = File.join(osx_place, "Arduino")
          ret.lib_dir = File.join(osx_place, "Libraries")
          return ret
        end

        posix_place = Host.which("arduino")
        unless posix_place.nil?
          ret.cmd_path = posix_place
          ret.lib_dir = File.join(ENV['HOME'], "Sketchbook") # assume linux
          # https://learn.adafruit.com/adafruit-all-about-arduino-libraries-install-use/how-to-install-a-library
          return ret
        end

        if File.exist? force_install_location
          ret.cmd_path = File.join(force_install_location, "arduino")
          ret.lib_dir = File.join(force_install_location, "libraries")
          # TODO: "libraries" is what's in the adafruit install.sh script
          return ret
        end

        ret
      end

      # Attempt to find a workable Arduino executable across platforms, and install it if we don't
      def autolocate!
        candidate = autolocate
        return candidate unless candidate.cmd_path.nil?
        # force the install

        if force_install
          candidate.cmd_path = File.join(force_install_location, "arduino")
          candidate.lib_dir = File.join(force_install_location, "libraries")
        end
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
