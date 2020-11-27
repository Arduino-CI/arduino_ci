require "arduino_ci/arduino_downloader"

module ArduinoCI

  # Manage the linux download & install of Arduino
  class ArduinoDownloaderLinux < ArduinoDownloader

    # The local filename of the desired IDE package (zip/tar/etc)
    # @return [string]
    def package_file
      "arduino-cli_#{@desired_version}_Linux_64bit.tar.gz"
    end

    # The local file (dir) name of the extracted IDE package (zip/tar/etc)
    # @return [string]
    def self.extracted_file
      "arduino-cli"
    end

    # The executable Arduino file in an existing installation, or nil
    # @return [string]
    def self.existing_executable
      Host.which("arduino-cli")
    end

    # Make any preparations or run any checks prior to making changes
    # @return [string] Error message, or nil if success
    def prepare
      reqs = [self.class.extracter]
      reqs.each do |req|
        return "#{req} does not appear to be installed!" unless Host.which(req)
      end
      nil
    end

    # The technology that will be used to extract the download
    # (for logging purposes)
    # @return [string]
    def self.extracter
      "tar"
    end

    # Extract the package_file to extracted_file
    # @return [bool] whether successful
    def self.extract(package_file)
      system(extracter, "xf", package_file, extracted_file)
    end

  end
end
