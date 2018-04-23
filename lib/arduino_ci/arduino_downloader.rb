DOWNLOAD_ATTEMPTS = 3

module ArduinoCI

  # Manage the OS-specific download & install of Arduino
  class ArduinoDownloader

    def initialize(desired_ide_version)
      @desired_ide_version = desired_ide_version
    end

    # Provide guidelines to the implementer of this class
    def must_implement(method)
      raise NoMethodError("#{self.class.name} failed to implement ArduinoDownloader.#{method}")
    end

    # Make any preparations or run any checks prior to making changes
    # @return [string] Error message, or nil if success
    def prepare
      nil
    end

    # The autolocated executable of the installation
    #
    # @return [string] or nil
    def self.autolocation
      # Arbitrarily, I'm going to pick the force installed location first
      # if it exists.  I'm not sure why we would have both, but if we did
      # a force install then let's make sure we actually use it.
      locations = [self.force_installed_executable, self.existing_executable]
      locations.each do |loc|
        next if loc.nil?
        next unless File.exist? loc
        return loc
      end
      nil
    end

    # The executable Arduino file in an existing installation, or nil
    # @return [string]
    def self.existing_executable
      must_implement(__method__)
    end

    # The executable Arduino file in a forced installation, or nil
    # @return [string]
    def self.force_installed_executable
      must_implement(__method__)
    end

    # The technology that will be used to complete the download
    # (for logging purposes)
    # @return [string]
    def downloader
      must_implement(__method__)
    end

    # The technology that will be used to extract the download
    # (for logging purposes)
    # @return [string]
    def extracter
      must_implement(__method__)
    end

    # The URL of the desired IDE package (zip/tar/etc) for this platform
    # @return [string]
    def package_url
      "https://downloads.arduino.cc/#{package_file}"
    end

    # The local file (dir) name of the desired IDE package (zip/tar/etc)
    # @return [string]
    def package_file
      must_implement(__method__)
    end

    # The local filename of the extracted IDE package (zip/tar/etc)
    # @return [string]
    def extracted_file
      must_implement(__method__)
    end

    # @return [String] The location where a forced install will go
    def self.force_install_location
      File.join(ENV['HOME'], 'arduino_ci_ide')
    end

    # Download the package_url to package_file, and maybe print a line of dots......
    # @return [bool] whether successful
    def download
      must_implement(__method__)
    end

    # Extract the package_file to extracted_file
    # @return [bool] whether successful
    def extract
      must_implement(__method__)
    end

    # Move the extracted package file from extracted_file to the force_install_location
    # @return [bool] whether successful
    def install
      must_implement(__method__)
    end

    # Forcibly install Arduino on linux from the web
    # @return [bool] Whether the command succeeded
    def execute
      error_preparing = prepare
      unless error_preparing.nil?
        puts "Arduino force-install failed preparation: #{error_preparing}"
        return false
      end

      attempts = 0

      loop do
        if File.exist? package_file
          puts "Arduino package seems to have been downloaded already" if attempts.zero?
          break
        elsif attempts >= DOWNLOAD_ATTEMPTS
          break puts "After #{DOWNLOAD_ATTEMPTS} attempts, failed to download #{package_url}"
        else
          puts "Attempting to download Arduino package with #{downloader}"
          download
        end
        attempts += 1
      end

      if File.exist? extracted_file
        puts "Arduino package seems to have been extracted already"
      elsif File.exist? package_file
        puts "Extracting archive with #{extracter}"
        extract
      end

      if File.exist? self.class.force_install_location
        puts "Arduino package seems to have been installed already"
      elsif File.exist? extracted_file
        install
      else
        puts "Arduino force-install failed"
      end

      File.exist? self.class.force_install_location
    end

  end
end
