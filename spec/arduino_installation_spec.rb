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
    it "doesn't fail" do
      installation = ArduinoCI::ArduinoInstallation.autolocate!
      expect(installation.base_cmd).not_to be nil
      expect(installation.lib_dir).not_to be nil
    end
  end

end

