require "arduino_ci/arduino_downloader_posix"

module ArduinoCI

  # Manage the OSX download & install of Arduino
  class ArduinoDownloaderOSX < ArduinoDownloaderPosix

    # The local filename of the desired IDE package (zip/tar/etc)
    # @return [string]
    def package_file
      "arduino-#{@desired_ide_version}-macosx.zip"
    end

    # The technology that will be used to extract the download
    # (for logging purposes)
    # @return [string]
    def extracter
      "unzip"
    end

    # Extract the package_file to extracted_file
    # @return [bool] whether successful
    def extract
      system(extracter, package_file)
    end

    # The local file (dir) name of the extracted IDE package (zip/tar/etc)
    # @return [string]
    def extracted_file
      "Arduino.app"
    end

    # An existing Arduino directory in one of the given directories, or nil
    # @param Array<string> a list of places to look
    # @return [string]
    def self.find_existing_arduino_dir(paths)
      paths.each do |path|
        return path if File.exist? path
      end
      nil
    end

    # An existing Arduino file in one of the given directories, or nil
    # @param Array<string> a list of places to look for the executable
    # @return [string]
    def self.find_existing_arduino_exe(paths)
      paths.each do |path|
        exe = File.join(path, "MacOS", "Arduino")
        return exe if File.exist? exe
      end
      nil
    end

    # The path to the directory of an existing installation, or nil
    # @return [string]
    def self.existing_installation
      self.find_existing_arduino_dir(["/Applications/Arduino.app/Contents"])
    end

    # The executable Arduino file in an existing installation, or nil
    # @return [string]
    def self.existing_executable
      self.find_existing_arduino_exe(["/Applications/Arduino.app/Contents"])
    end

    # The executable Arduino file in a forced installation, or nil
    # @return [string]
    def self.force_installed_executable
      self.find_existing_arduino_exe([File.join(self.force_install_location, "Contents")])
    end

  end
end
