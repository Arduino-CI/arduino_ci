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

  context "board_installed?" do
    arduino_cmd = ArduinoCI::ArduinoCmd.autolocate!
    ArduinoCI::DisplayManager::instance.enable
    it "Finds installed boards" do
      expect(arduino_cmd.board_installed? "arduino:avr:uno").to be true
    end

    it "Doesn't find bogus boards" do
      expect(arduino_cmd.board_installed? "eggs:milk:wheat").to be false
    end
  end
end
