require "arduino_ci/arduino_downloader"

module ArduinoCI

  # Manage the POSIX download & install of Arduino
  class ArduinoDownloaderPosix < ArduinoDownloader

    # Make any preparations or run any checks prior to making changes
    # @return [string] Error message, or nil if success
    def prepare
      reqs = [downloader, extracter]
      reqs.each do |req|
        return "#{req} does not appear to be installed!" unless Host.which(req)
      end
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
      system(downloader, "--quiet", "--progress=dot:giga", package_url)
    end

    # Move the extracted package file from extracted_file to the force_install_location
    # @return [bool] whether successful
    def install
      system("mv", extracted_file, self.class.force_install_location)
    end

  end
end
