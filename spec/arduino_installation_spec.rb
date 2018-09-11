require "spec_helper"

RSpec.describe ArduinoCI::ArduinoInstallation do
  context "autolocate" do
    it "doesn't fail" do
      ArduinoCI::ArduinoInstallation.autolocate
    end
  end

  context "autolocate!" do
    arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!
    it "doesn't fail" do
      expect(arduino_cmd.base_cmd).not_to be nil
      expect(arduino_cmd._lib_dir).not_to be nil
    end
  end

end

