require "spec_helper"
require 'pathname'

def get_sketch(dir, file)
  File.join(File.dirname(__FILE__), dir, file)
end


RSpec.describe ArduinoCI::ArduinoCmd do
  next if skip_splash_screen_tests

  arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!

  after(:each) do |example|
    if example.exception
      puts "Last message: #{arduino_cmd.last_msg}"
      puts "========== Stdout:"
      puts arduino_cmd.last_out
      puts "========== Stderr:"
      puts arduino_cmd.last_err
    end
  end

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

  context "installation of boards" do
    it "installs and sets boards" do
      expect(arduino_cmd.install_boards("arduino:sam")).to be true
      expect(arduino_cmd.use_board("arduino:sam:arduino_due_x")).to be true
    end
  end

  context "libraries" do
    it "knows where to find libraries" do
      fake_lib = "_____nope"
      expected_dir = Pathname.new(arduino_cmd.lib_dir) + fake_lib
      expect(arduino_cmd.library_path(fake_lib)).to eq(expected_dir)
      expect(arduino_cmd.library_present?(fake_lib)).to be false
    end
  end

  context "set_pref" do

    it "Sets key to what it was before" do
      upload_verify = arduino_cmd.get_pref("upload.verify")
      result = arduino_cmd.set_pref("upload.verify", upload_verify)
      expect(result).to be true
    end
  end


  context "board_manager" do
    it "Reads and writes board_manager URLs" do
      fake_urls = ["http://foo.bar", "http://arduino.ci"]
      existing_urls = arduino_cmd.board_manager_urls

      # try to ensure maxiumum variability in the test
      test_url_sets = (existing_urls.empty? ? [fake_urls, []] : [[], fake_urls]) + [existing_urls]

      test_url_sets.each do |urls|
        arduino_cmd.board_manager_urls = urls
        expect(arduino_cmd.board_manager_urls).to match_array(urls)
      end
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
