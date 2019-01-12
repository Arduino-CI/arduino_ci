require 'base64'
require 'shellwords' # fingers crossed this works on win32
require 'win32/registry'
require "arduino_ci/arduino_downloader"
require "fileutils"

module ArduinoCI

  # Manage the POSIX download & install of Arduino
  class ArduinoDownloaderWindows < ArduinoDownloader

    # Make any preparations or run any checks prior to making changes
    # @return [string] Error message, or nil if success
    def prepare
      nil
    end

    # The technology that will be used to complete the download
    # (for logging purposes)
    # @return [string]
    def downloader
      "open-uri"
    end

    # Download the package_url to package_file
    # @return [bool] whether successful
    def download
      # Turned off ssl verification
      # This should be acceptable because it won't happen on a user's machine, just CI
      open(URI.parse(package_url), ssl_verify_mode: 0) do |url|
        File.open(package_file, 'wb') { |file| file.write(url.read) }
      end
    end

    # Move the extracted package file from extracted_file to the force_install_location
    # @return [bool] whether successful
    def install
      # Move only the content of the directory
      FileUtils.mv extracted_file, self.class.force_install_location
    end

    # The local filename of the desired IDE package (zip/tar/etc)
    # @return [string]
    def package_file
      "#{extracted_file}-windows.zip"
    end

    # The technology that will be used to extract the download
    # (for logging purposes)
    # @return [string]
    def extracter
      "Expand-Archive"
    end

    # Extract the package_file to extracted_file
    # @return [bool] whether successful
    def extract
      Zip::File.open(package_file) do |zip|
        zip.each do |file|
          file.extract(file.name)
        end
      end
    end

    # The local file (dir) name of the extracted IDE package (zip/tar/etc)
    # @return [string]
    def extracted_file
      "arduino-#{@desired_ide_version}"
    end

    # The path to the directory of an existing installation, or nil
    # @return [string]
    def self.existing_installation
      exe = self.existing_executable
      return nil if exe.nil?

      File.dirname(exe)
    end

    # The executable Arduino file in an existing installation, or nil
    # @return [string]
    def self.existing_executable
      arduino_reg = 'SOFTWARE\WOW6432Node\Arduino'
      Win32::Registry::HKEY_LOCAL_MACHINE.open(arduino_reg).find do |reg|
        path = reg.read_s('Install_Dir')
        exe = File.join(path, "arduino_debug.exe")
        File.exist? exe
      end
    rescue
      nil
    end

    # The executable Arduino file in a forced installation, or nil
    # @return [string]
    def self.force_installed_executable
      File.join(self.force_install_location, "arduino_debug.exe")
    end

  end
end
