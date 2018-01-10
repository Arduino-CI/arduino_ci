require "spec_helper"

RSpec.describe ArduinoCI::ArduinoCmd do
  it "Finds the Arduino executable" do
    arduino_cmd = ArduinoCI::ArduinoCmd.autolocate
    # expect(arduino_cmd.path).not_to be nil
  end
end

RSpec.describe ArduinoCI::ArduinoCmd::DisplayMgr do
  context "singleton ::instance" do
    it "produces an instance" do
      expect(ArduinoCI::ArduinoCmd::DisplayMgr::instance).not_to be_nil
    end
  end

  context "with_display" do
    it "Properly enables and disables" do
      manager = ArduinoCI::ArduinoCmd::DisplayMgr::instance
      expect(manager.enabled).to be false
      manager.with_display do |environment|
        expect(manager.enabled).to be true
        expect(environment.class).to eq(Hash)
        also_manager = ArduinoCI::ArduinoCmd::DisplayMgr::instance
        expect(also_manager.enabled).to be true
      end
      expect(manager.enabled).to be false
    end
  end
end
