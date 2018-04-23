require "spec_helper"

DESIRED_VERSION = "rhubarb"
RSpec.describe ArduinoCI::ArduinoDownloader do
  context "Basics" do
    it "can instantiate" do
      ArduinoCI::ArduinoDownloader.new(DESIRED_VERSION)
    end
  end

end
RSpec.describe ArduinoCI::ArduinoDownloaderLinux do
  context "Basics" do
    it "can instantiate" do
      ArduinoCI::ArduinoDownloaderLinux.new(DESIRED_VERSION)
    end
  end

end
