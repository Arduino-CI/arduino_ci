require "spec_helper"

def get_sketch(dir, file)
  File.join(File.dirname(__FILE__), dir, file)
end


RSpec.describe ArduinoCI::ArduinoCmd do
  arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!
  context "initialize" do
    it "sets base vars" do
      expect(arduino_cmd.base_cmd).not_to be nil
      expect(arduino_cmd.prefs.class).to be Hash
    end
  end

  context "board_installed?" do
    it "Finds installed boards" do
      uno_installed = arduino_cmd.board_installed? "arduino:avr:uno"
      expect(uno_installed).to be true
      expect(uno_installed).not_to be nil
    end

    it "Doesn't find bogus boards" do
      bogus_installed = arduino_cmd.board_installed? "eggs:milk:wheat"
      expect(bogus_installed).to be false
      expect(bogus_installed).not_to be nil
    end
  end

  context "set_pref" do

    it "Sets key to what it was before" do
      upload_verify = arduino_cmd.get_pref("upload.verify")
      result = arduino_cmd.set_pref("upload.verify", upload_verify)
      expect(result).to be true
    end
  end

  context "verify_sketch" do

    sketch_path_ino = get_sketch("FakeSketch", "FakeSketch.ino")
    sketch_path_pde = get_sketch("FakeSketch", "FakeSketch.pde")
    sketch_path_mia = get_sketch("NO_FILE_HERE", "foo.ino")
    sketch_path_bad = get_sketch("BadSketch", "BadSketch.ino")

    it "Rejects a PDE sketch at #{sketch_path_pde}" do
      expect(arduino_cmd.verify_sketch(sketch_path_pde)).to be false
    end

    it "Fails a missing sketch at #{sketch_path_mia}" do
      expect(arduino_cmd.verify_sketch(sketch_path_mia)).to be false
    end

    it "Fails a bad sketch at #{sketch_path_bad}" do
      expect(arduino_cmd.verify_sketch(sketch_path_bad)).to be false
    end

    it "Passes a simple INO sketch at #{sketch_path_ino}" do
      expect(arduino_cmd.verify_sketch(sketch_path_ino)).to be true
    end

  end
end
