require "spec_helper"

DESIRED_VERSION = "rhubarb"
RSpec.describe ArduinoCI::ArduinoDownloader do
  context "Basics" do
    it "has correct class properties" do
      ad = ArduinoCI::ArduinoDownloader

      expect{ad.autolocated_executable}.to raise_error(NotImplementedError)
      expect{ad.autolocated_installation}.to raise_error(NotImplementedError)
      expect{ad.existing_installation}.to raise_error(NotImplementedError)
      expect{ad.existing_executable}.to raise_error(NotImplementedError)
      expect{ad.force_installed_executable}.to raise_error(NotImplementedError)
      expect(ad.force_install_location).to eq(File.join(ENV['HOME'], 'arduino_ci_ide'))
    end

    it "has correct instance properties" do
      ad = ArduinoCI::ArduinoDownloader.new(DESIRED_VERSION)
      expect(ad.prepare).to be nil
      expect{ad.package_url}.to raise_error(NotImplementedError)
      expect{ad.package_file}.to raise_error(NotImplementedError)
    end
  end
end

RSpec.describe ArduinoCI::ArduinoDownloaderLinux do
  context "Basics" do
    it "has correct class properties" do
      ad = ArduinoCI::ArduinoDownloaderLinux
      # these will vary with CI.  Don't test them.
      # expect(ad.autolocated_executable).to be nil
      # expect(ad.autolocated_installation).to be nil
      # expect(ad.existing_installation).to be nil
      # expect(ad.existing_executable).to be nil
      # expect(ad.force_installed_executable).to be nil

      expect(ad.force_install_location).to eq(File.join(ENV['HOME'], 'arduino_ci_ide'))
    end

    it "has correct instance properties" do
      ad = ArduinoCI::ArduinoDownloaderLinux.new(DESIRED_VERSION)
      expect(ad.prepare).to be nil
      expect(ad.downloader).to eq("open-uri")
      expect(ad.extracter).to eq("tar")
      expect(ad.package_url).to eq("https://downloads.arduino.cc/arduino-rhubarb-linux64.tar.xz")
      expect(ad.package_file).to eq("arduino-rhubarb-linux64.tar.xz")
    end
  end
end

RSpec.describe ArduinoCI::ArduinoDownloaderOSX do
  context "Basics" do
    it "has correct class properties" do
      ad = ArduinoCI::ArduinoDownloaderOSX
      # these will vary with CI.  Don't test them.
      # expect(ad.autolocated_executable).to be nil
      # expect(ad.autolocated_installation).to be nil
      # expect(ad.existing_installation).to be nil
      # expect(ad.existing_executable).to be nil
      # expect(ad.force_installed_executable).to be nil

      expect(ad.force_install_location).to eq(File.join(ENV['HOME'], 'Arduino.app'))
    end

    it "has correct instance properties" do
      ad = ArduinoCI::ArduinoDownloaderOSX.new(DESIRED_VERSION)
      expect(ad.prepare).to be nil
      expect(ad.downloader).to eq("open-uri")
      expect(ad.extracter).to eq("Zip")
      expect(ad.package_url).to eq("https://downloads.arduino.cc/arduino-rhubarb-macosx.zip")
      expect(ad.package_file).to eq("arduino-rhubarb-macosx.zip")
    end
  end
end
