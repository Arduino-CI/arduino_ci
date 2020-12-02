require 'fileutils'
require 'pathname'
require 'net/http'
require 'open-uri'
require 'zip'

DOWNLOAD_ATTEMPTS = 3

module ArduinoCI

  # Manage the OS-specific download & install of Arduino
  class ArduinoDownloader

    # @param desired_version [string] Version string e.g. 1.8.7
    # @param output [IO] $stdout, $stderr, File.new(/dev/null, 'w'), etc. where console output will be sent
    def initialize(desired_version, output = $stdout)
      @desired_version = desired_version
      @output = output
    end

    # Provide guidelines to the implementer of this class
    def self.must_implement(method)
      raise NotImplementedError, "#{self.class.name} failed to implement ArduinoDownloader.#{method}"
    end

    # Make any preparations or run any checks prior to making changes
    # @return [string] Error message, or nil if success
    def prepare
      nil
    end

    # The autolocated executable of the installation
    #
    # @return [Pathname] or nil
    def self.autolocated_executable
      # Arbitrarily, I'm going to pick the force installed location first
      # if it exists.  I'm not sure why we would have both, but if we did
      # a force install then let's make sure we actually use it.
      locations = [self.force_installed_executable, self.existing_executable]
      locations.find { |loc| !loc.nil? && File.exist?(loc) }
    end

    # The executable Arduino file in an existing installation, or nil
    # @return [Pathname]
    def self.existing_executable
      self.must_implement(__method__)
    end

    # The local file (dir) name of the desired IDE package (zip/tar/etc)
    # @return [string]
    def package_file
      self.class.must_implement(__method__)
    end

    # The local filename of the extracted IDE package (zip/tar/etc)
    # @return [string]
    def self.extracted_file
      self.must_implement(__method__)
    end

    # The executable Arduino file in a forced installation, or nil
    # @return [Pathname]
    def self.force_installed_executable
      Pathname.new(ENV['HOME']) + self.extracted_file
    end

    # The technology that will be used to complete the download
    # (for logging purposes)
    # @return [string]
    def self.downloader
      "open-uri"
    end

    # The technology that will be used to extract the download
    # (for logging purposes)
    # @return [string]
    def self.extracter
      self.must_implement(__method__)
    end

    # Extract the package_file to extracted_file
    # @return [bool] whether successful
    def self.extract(_package_file)
      self.must_implement(__method__)
    end

    # The URL of the desired IDE package (zip/tar/etc) for this platform
    # @return [string]
    def package_url
      "https://github.com/arduino/arduino-cli/releases/download/#{@desired_version}/#{package_file}"
    end

    # Download the package_url to package_file
    # @return [bool] whether successful
    def download
      # Turned off ssl verification
      # This should be acceptable because it won't happen on a user's machine, just CI

      # define a progress-bar printer
      chunk_size = 1024 * 1024 * 1024
      total_size = 0
      dots = 0
      dot_printer = lambda do |size|
        total_size += size
        needed_dots = (total_size / chunk_size).to_i
        unprinted_dots = needed_dots - dots
        @output.print("." * unprinted_dots) if unprinted_dots.positive?
        dots = needed_dots
      end

      open(package_url, ssl_verify_mode: 0, progress_proc: dot_printer) do |url|
        File.open(package_file, 'wb') { |file| file.write(url.read) }
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, OpenURI::HTTPError, URI::InvalidURIError => e
      @output.puts "\nArduino force-install failed downloading #{package_url}: #{e}"
    end

    # Move the extracted package file from extracted_file to the force_installed_executable
    # @return [bool] whether successful
    def install
      FileUtils.mv self.class.extracted_file.to_s, self.class.force_installed_executable.to_s
    end

    # Forcibly install Arduino on linux from the web
    # @return [bool] Whether the command succeeded
    def execute
      error_preparing = prepare
      unless error_preparing.nil?
        @output.puts "Arduino force-install failed preparation: #{error_preparing}"
        return false
      end

      arduino_package = "Arduino #{@desired_version} package"
      attempts = 0

      loop do
        if File.exist?(package_file)
          @output.puts "#{arduino_package} seems to have been downloaded already at #{package_file}" if attempts.zero?
          break
        elsif attempts >= DOWNLOAD_ATTEMPTS
          break @output.puts "After #{DOWNLOAD_ATTEMPTS} attempts, failed to download #{package_url}"
        else
          @output.print "Attempting to download #{arduino_package} with #{self.class.downloader}"
          download
          @output.puts
        end
        attempts += 1
      end

      if File.exist?(self.class.extracted_file)
        @output.puts "#{arduino_package} seems to have been extracted already at #{self.class.extracted_file}"
      elsif File.exist?(package_file)
        @output.print "Extracting archive with #{self.class.extracter}"
        self.class.extract(package_file)
        @output.puts
      end

      if File.exist?(self.class.force_installed_executable)
        @output.puts "#{arduino_package} seems to have been installed already at #{self.class.force_installed_executable}"
      elsif File.exist?(self.class.extracted_file)
        install
      else
        @output.puts "Could not find extracted archive (tried #{self.class.extracted_file})"
      end

      File.exist?(self.class.force_installed_executable)
    end

  end
end
