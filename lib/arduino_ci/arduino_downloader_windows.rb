require 'base64'
require 'shellwords' # fingers crossed this works on win32
require 'win32/registry'
require "arduino_ci/arduino_downloader"
require 'net/http'
require "fileutils"

module ArduinoCI

  # Manage the POSIX download & install of Arduino
  class ArduinoDownloaderWindows < ArduinoDownloader

    # Download the package_url to package_file
    # @return [bool] whether successful
    def download
      # Turned off ssl verification
      # This should be acceptable because it won't happen on a user's machine, just CI
      open(URI.parse(package_url), ssl_verify_mode: 0) do |url|
        File.open(package_file, 'wb') { |file| file.write(url.read) }
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, OpenURI::HTTPError, URI::InvalidURIError => e
      @output.puts "\nArduino force-install failed downloading #{package_url}: #{e}"
    end

    # The local filename of the desired IDE package (zip/tar/etc)
    # @return [string]
    def package_file
      "arduino-cli_#{@desired_version}_Windows_64bit.zip"
    end

    # The executable Arduino file in an existing installation, or nil
    # @return [string]
    def self.existing_executable
      Host.which("arduino-cli")
    end

    # The technology that will be used to extract the download
    # (for logging purposes)
    # @return [string]
    def self.extracter
      "Expand-Archive"
    end

    # Extract the package_file to extracted_file
    # @return [bool] whether successful
    def self.extract(package_file)
      Zip::File.open(package_file) do |zip|
        zip.each do |file|
          file.extract(file.name)
        end
      end
    end

    # The local file (dir) name of the extracted IDE package (zip/tar/etc)
    # @return [string]
    def self.extracted_file
      "arduino-cli.exe"
    end

  end
end
