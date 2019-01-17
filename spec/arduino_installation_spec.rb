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
      expect(arduino_cmd.lib_dir).not_to be nil
    end
  end

  context "force_install" do
    it "Can redirect output" do
      output = StringIO.new
      output.rewind
      expect(output.read.empty?).to be true
      # install a bogus version to save time downloading
      arduino_cmd = ArduinoCI::ArduinoInstallation.force_install(output, "BOGUS VERSION")
      output.rewind
      expect(output.read.empty?).to be false
    end
  end

end

