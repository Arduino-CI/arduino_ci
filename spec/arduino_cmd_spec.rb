require "spec_helper"

RSpec.describe ArduinoCI::ArduinoCmd do
  it "Finds the Arduino executable" do
    arduino_cmd = ArduinoCI::ArduinoCmd.autolocate
    # expect(arduino_cmd.path).not_to be nil
  end
end

