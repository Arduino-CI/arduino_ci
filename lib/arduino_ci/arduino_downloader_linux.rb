require "arduino_ci/arduino_downloader_posix"

USE_BUILDER = false

module ArduinoCI

  # Manage the linux download & install of Arduino
  class ArduinoDownloaderLinux < ArduinoDownloaderPosix

    # The local filename of the desired IDE package (zip/tar/etc)
    # @return [string]
    def package_file
      "#{extracted_file}-linux64.tar.xz"
    end

    # The technology that will be used to extract the download
    # (for logging purposes)
    # @return [string]
    def extracter
      "tar"
    end

    # Extract the package_file to extracted_file
    # @return [bool] whether successful
    def extract
      system(extracter, "xf", package_file)
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
      File.dirname(exe) # it's not really this
      # but for this platform it doesn't really matter
    end

    # The executable Arduino file in an existing installation, or nil
    # @return [string]
    def self.existing_executable
      if USE_BUILDER
        # builder_name = "arduino-builder"
        # cli_place = Host.which(builder_name)
        # unless cli_place.nil?
        #   ret = ArduinoCmdLinuxBuilder.new
        #   ret.base_cmd = [cli_place]
        #   return ret
        # end
      end
      Host.which("arduino")
    end

    # The executable Arduino file in a forced installation, or nil
    # @return [string]
    def self.force_installed_executable
      if USE_BUILDER
        # forced_builder = File.join(ArduinoCmdLinuxBuilder.force_install_location, builder_name)
        # if File.exist?(forced_builder)
        #   ret = ArduinoCmdLinuxBuilder.new
        #   ret.base_cmd = [forced_builder]
        #   return ret
        # end
      end
      forced_arduino = File.join(self.force_install_location, "arduino")
      return forced_arduino if File.exist? forced_arduino
      nil
    end

  end
end
