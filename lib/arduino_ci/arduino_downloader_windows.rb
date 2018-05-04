require 'base64'
require 'shellwords' # fingers crossed this works on win32
require 'win32/registry'
require "arduino_ci/arduino_downloader"

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
      "wget"
    end

    # Download the package_url to package_file
    # @return [bool] whether successful
    def download
      powershell("(New-Object Net.WebClient).DownloadFile('#{package_url}', '#{package_file}')")
    end

    # Move the extracted package file from extracted_file to the force_install_location
    # @return [bool] whether successful
    def install
      powershell("Move-Item", extracted_file, self.class.force_install_location)
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
      powershell("Expand-Archive", package_file, "-dest", extracted_file)
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
      Win32::Registry::HKEY_LOCAL_MACHINE.open(arduino_reg) do |reg|
        path = reg.read_s('Install_Dir')
        puts 'Arduino Install Dir: ' + path
        exe = File.join(path, "arduino.exe")
        return exe if File.exist? exe
      end
      nil
    end

    # The executable Arduino file in a forced installation, or nil
    # @return [string]
    def self.force_installed_executable
      exe = File.join(self.force_install_location, "arduino.exe")
      return nil if exe.nil?
      exe
    end

  end
end
