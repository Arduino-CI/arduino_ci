require 'base64'
require 'shellwords' # fingers crossed this works on win32
require 'win32/registry'
require "arduino_ci/arduino_downloader"
require 'open-uri'

module ArduinoCI

  # Manage the POSIX download & install of Arduino
  class ArduinoDownloaderWindows < ArduinoDownloader

    def powershell(*args)
      encoded_cmd = Base64.strict_encode64(args.shelljoin.encode('utf-16le'))
      system("powershell.exe", "-encodedCommand", encoded_cmd)
    end

    def cygwin(*args)
      system("%CYG_ROOT%/bin/bash", "-lc", args.shelljoin)
    end

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
      puts 'Downloading from ' + package_url
      open(URI.parse(package_url)) do |url|
        File.open(package_file, 'wb') { |file| file.write(url.read) }
      end
    end

    # Move the extracted package file from extracted_file to the force_install_location
    # @return [bool] whether successful
    def install
      puts 'Installing to ' + self.class.force_install_location
      # Move only the content of the directory
      powershell("Move-Item", extracted_file + "\*", self.class.force_install_location)
      # clean up the no longer required root extracted folder
      puts 'Removing ' + package_file
      powershell("Remove-Item", extracted_file)
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
      puts 'Extracting ' + package_file + " to " + extracted_file
      powershell("Expand-Archive", "-Path", package_file, "-DestinationPath", extracted_file)
      # clean up the no longer required zip
      puts 'Removing ' + package_file
      powershell("Remove-Item", package_file)
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
      arduino_reg = 'SOFTWARE\WOW6432Node\Arduino1'
      Win32::Registry::HKEY_LOCAL_MACHINE.open(arduino_reg) do |reg|
        path = reg.read_s('Install_Dir')
        exe = File.join(path, "arduino_debug.exe")
        puts "Using existing exe located at " + exe
        return exe if File.exist? exe
      end
    rescue
      nil
    end

    # The executable Arduino file in a forced installation, or nil
    # @return [string]
    def self.force_installed_executable
      exe = File.join(self.force_install_location, "arduino_debug.exe")
      puts "using force installed exe located at " + exe
      return nil if exe.nil?
      exe
    end

  end
end
