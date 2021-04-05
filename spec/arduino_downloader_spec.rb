require "spec_helper"

DESIRED_VERSION = "rhubarb"
RSpec.describe ArduinoCI::ArduinoDownloader do
  next if skip_ruby_tests
  context "Basics" do
    it "has correct class properties" do
      ad = ArduinoCI::ArduinoDownloader

      expect{ad.extracted_file}.to raise_error(NotImplementedError)
      expect{ad.extracter}.to raise_error(NotImplementedError)
      expect{ad.extract("foo")}.to raise_error(NotImplementedError)
    end

    it "has correct instance properties" do
      ad = ArduinoCI::ArduinoDownloader.new(DESIRED_VERSION)
      expect(ad.prepare).to be nil
      expect{ad.package_file}.to raise_error(NotImplementedError)
    end
  end
end

RSpec.describe ArduinoCI::ArduinoDownloaderLinux do
  next if skip_ruby_tests
  context "Basics" do
    it "has correct class properties" do
      ad = ArduinoCI::ArduinoDownloaderLinux
      # these can vary with CI.  Don't test them.
      # expect(ad.existing_executable).to be nil
      # expect(ad.autolocated_executable).to be nil
      # expect(ad.force_installed_executable).to be nil

      expect(ad.downloader).to eq("open-uri")
      expect(ad.extracter).to eq("tar")
    end

    it "has correct instance properties" do
      ad = ArduinoCI::ArduinoDownloaderLinux.new(DESIRED_VERSION)
      expect(ad.prepare).to be nil
      expect(ad.package_url).to eq("https://github.com/arduino/arduino-cli/releases/download/rhubarb/arduino-cli_rhubarb_Linux_64bit.tar.gz")
      expect(ad.package_file).to eq("arduino-cli_rhubarb_Linux_64bit.tar.gz")
    end
  end
end

RSpec.describe ArduinoCI::ArduinoDownloaderOSX do
  next if skip_ruby_tests
  context "Basics" do
    it "has correct class properties" do
      ad = ArduinoCI::ArduinoDownloaderOSX
      # these can vary with CI.  Don't test them.
      # expect(ad.existing_executable).to be nil
      # expect(ad.autolocated_executable).to be nil
      # expect(ad.force_installed_executable).to be nil

      expect(ad.downloader).to eq("open-uri")
      expect(ad.extracter).to eq("tar")
    end

    it "has correct instance properties" do
      ad = ArduinoCI::ArduinoDownloaderOSX.new(DESIRED_VERSION)
      expect(ad.prepare).to be nil
      expect(ad.package_url).to eq("https://github.com/arduino/arduino-cli/releases/download/rhubarb/arduino-cli_rhubarb_macOS_64bit.tar.gz")
      expect(ad.package_file).to eq("arduino-cli_rhubarb_macOS_64bit.tar.gz")
    end
  end
end


if ArduinoCI::Host.os == :windows
  RSpec.describe ArduinoCI::ArduinoDownloaderWindows do
    next if skip_ruby_tests
    context "Basics" do
      it "has correct class properties" do
        ad = ArduinoCI::ArduinoDownloaderWindows
        # these will vary with CI.  Don't test them.
        # expect(ad.autolocated_executable).to be nil
        # expect(ad.existing_executable).to be nil
        # expect(ad.force_installed_executable).to be nil

        expect(ad.downloader).to eq("open-uri")
        expect(ad.extracter).to eq("Expand-Archive")
      end

      it "has correct instance properties" do
        ad = ArduinoCI::ArduinoDownloaderWindows.new(DESIRED_VERSION)
        expect(ad.prepare).to be nil
        expect(ad.package_url).to eq("https://github.com/arduino/arduino-cli/releases/download/rhubarb/arduino-cli_rhubarb_Windows_64bit.zip")
        expect(ad.package_file).to eq("arduino-cli_rhubarb_Windows_64bit.zip")
      end
    end
  end


end
