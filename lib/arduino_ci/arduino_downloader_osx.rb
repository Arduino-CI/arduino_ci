require "arduino_ci/arduino_downloader"

module ArduinoCI

  # Manage the OSX download & install of Arduino
  class ArduinoDownloaderOSX < ArduinoDownloader

    # The local filename of the desired IDE package (zip/tar/etc)
    # @return [string]
    def package_file
      "arduino-#{@desired_ide_version}-macosx.zip"
    end

    # The local file (dir) name of the extracted IDE package (zip/tar/etc)
    # @return [string]
    def extracted_file
      "Arduino.app"
    end

    # @return [String] The location where a forced install will go
    def self.force_install_location
      # include the .app extension
      File.join(ENV['HOME'], 'Arduino.app')
    end

    # An existing Arduino directory in one of the given directories, or nil
    # @param Array<string> a list of places to look
    # @return [string]
    def self.find_existing_arduino_dir(paths)
      paths.find(&File.method(:exist?))
    end

    # An existing Arduino file in one of the given directories, or nil
    # @param Array<string> a list of places to look for the executable
    # @return [string]
    def self.find_existing_arduino_exe(paths)
      paths.find do |path|
        exe = File.join(path, "MacOS", "Arduino")
        File.exist? exe
      end
    end

    # The path to the directory of an existing installation, or nil
    # @return [string]
    def self.existing_installation
      self.find_existing_arduino_dir(["/Applications/Arduino.app"])
    end

    # The executable Arduino file in an existing installation, or nil
    # @return [string]
    def self.existing_executable
      self.find_existing_arduino_exe(["/Applications/Arduino.app"])
    end

    # The executable Arduino file in a forced installation, or nil
    # @return [string]
    def self.force_installed_executable
      self.find_existing_arduino_exe([self.force_install_location])
    end

  end
end
