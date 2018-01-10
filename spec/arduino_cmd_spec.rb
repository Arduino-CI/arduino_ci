require "spec_helper"

RSpec.describe ArduinoCI::ArduinoCmd do
  context "autolocate" do
    it "Finds the Arduino executable" do
      arduino_cmd = ArduinoCI::ArduinoCmd.autolocate
    end
  end

  context "autolocate!" do
    it "Finds the Arduino executable" do
      arduino_cmd = ArduinoCI::ArduinoCmd.autolocate!
      expect(arduino_cmd.installation.cmd_path).not_to be nil
    end
  end
end

