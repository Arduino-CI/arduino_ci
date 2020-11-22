require "spec_helper"
require 'pathname'

def get_sketch(dir, file)
  File.join(File.dirname(__FILE__), dir, file)
end


RSpec.describe ArduinoCI::ArduinoBackend do
  next if skip_ruby_tests

  arduino_backend = ArduinoCI::ArduinoInstallation.autolocate!

  after(:each) do |example|
    if example.exception
      puts "Last message: #{arduino_backend.last_msg}"
      puts "========== Stdout:"
      puts arduino_backend.last_out
      puts "========== Stderr:"
      puts arduino_backend.last_err
    end
  end

  context "initialize" do
    it "sets base vars" do
      expect(arduino_backend.binary_path).not_to be nil
    end
  end

  context "board_installed?" do
    it "Finds installed boards" do
      uno_installed = arduino_backend.board_installed? "arduino:avr:uno"
      expect(uno_installed).to be true
      expect(uno_installed).not_to be nil
    end

    it "Doesn't find bogus boards" do
      bogus_installed = arduino_backend.board_installed? "eggs:milk:wheat"
      expect(bogus_installed).to be false
      expect(bogus_installed).not_to be nil
    end
  end

  context "installation of boards" do
    it "installs and sets boards" do
      expect(arduino_backend.install_boards("arduino:sam")).to be true
    end
  end

  context "libraries" do
    it "knows where to find libraries" do
      fake_lib = "_____nope"
      expected_dir = Pathname.new(arduino_backend.lib_dir) + fake_lib
      expect(arduino_backend.library_path(fake_lib)).to eq(expected_dir)
      expect(arduino_backend.library_present?(fake_lib)).to be false
    end
  end

  context "board_manager" do
    it "Reads and writes board_manager URLs" do
      fake_urls = ["http://foo.bar", "http://arduino.ci"]
      existing_urls = arduino_backend.board_manager_urls

      # try to ensure maxiumum variability in the test
      test_url_sets = (existing_urls.empty? ? [fake_urls, []] : [[], fake_urls]) + [existing_urls]

      test_url_sets.each do |urls|
        arduino_backend.board_manager_urls = urls
        expect(arduino_backend.board_manager_urls).to match_array(urls)
      end
    end
  end


  context "compile_sketch" do

    sketch_path_ino = get_sketch("FakeSketch", "FakeSketch.ino")
    sketch_path_pde = get_sketch("FakeSketch", "FakeSketch.pde")
    sketch_path_mia = get_sketch("NO_FILE_HERE", "foo.ino")
    sketch_path_bad = get_sketch("BadSketch", "BadSketch.ino")

    it "Rejects a PDE sketch at #{sketch_path_pde}" do
      expect(arduino_backend.compile_sketch(sketch_path_pde, "arduino:avr:uno")).to be false
    end

    it "Fails a missing sketch at #{sketch_path_mia}" do
      expect(arduino_backend.compile_sketch(sketch_path_mia, "arduino:avr:uno")).to be false
    end

    it "Fails a bad sketch at #{sketch_path_bad}" do
      expect(arduino_backend.compile_sketch(sketch_path_bad, "arduino:avr:uno")).to be false
    end

    it "Passes a simple INO sketch at #{sketch_path_ino}" do
      expect(arduino_backend.compile_sketch(sketch_path_ino, "arduino:avr:uno")).to be true
    end
  end
end
