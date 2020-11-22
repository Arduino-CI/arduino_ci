require "spec_helper"

RSpec.describe ArduinoCI::ArduinoInstallation do
  next if skip_ruby_tests

  context "autolocate" do
    it "doesn't fail" do
      ArduinoCI::ArduinoInstallation.autolocate
    end
  end

  context "autolocate!" do
    backend = ArduinoCI::ArduinoInstallation.autolocate!
    it "doesn't fail" do
      expect(backend.binary_path).not_to be nil
      expect(backend.lib_dir).not_to be nil
    end
  end

  context "force_install" do
    it "Can redirect output" do
      output = StringIO.new
      output.rewind
      expect(output.read.empty?).to be true
      # install a bogus version to save time downloading
      backend = ArduinoCI::ArduinoInstallation.force_install(output, "BOGUS VERSION")
      output.rewind
      expect(output.read.empty?).to be false
    end
  end

end
