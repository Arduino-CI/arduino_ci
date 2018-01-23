require "spec_helper"

RSpec.describe ArduinoCI::ArduinoInstallation do
  context "force_install_location" do
    it "is resolvable" do
      expect(ArduinoCI::ArduinoInstallation.force_install_location).not_to be nil
    end
  end

  context "autolocate" do
    it "doesn't fail" do
      ArduinoCI::ArduinoInstallation.autolocate
    end
  end

  context "autolocate!" do
    arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!
    it "doesn't fail" do
      expect(arduino_cmd.base_cmd).not_to be nil
      expect(arduino_cmd.gcc_cmd).not_to be nil
      expect(arduino_cmd._lib_dir).not_to be nil
    end

    it "produces a working AVR-GCC" do
      expect(arduino_cmd.gcc_cmd).not_to be nil
      expect(arduino_cmd.run_gcc("--version")).to be true
    end
  end

end

