require "spec_helper"

def get_sketch(dir, file)
  Pathname.new(__FILE__).parent + dir + file
end

RSpec.describe ArduinoCI::ArduinoBackend do
  next if skip_ruby_tests

  backend = ArduinoCI::ArduinoInstallation.autolocate!

  after(:each) do |example|
    if example.exception
      puts "Last message: #{backend.last_msg}"
      puts "========== Stdout:"
      puts backend.last_out
      puts "========== Stderr:"
      puts backend.last_err
    end
  end

  context "initialize" do
    it "sets base vars" do
      expect(backend.binary_path).not_to be nil
    end
  end

  context "board_installed?" do
    it "Finds installed boards" do
      backend.install_boards("arduino:avr") # we used to assume this was installed... not the case for arduino-cli
      uno_installed = backend.board_installed? "arduino:avr:uno"
      expect(uno_installed).to be true
      expect(uno_installed).not_to be nil
    end

    it "Doesn't find bogus boards" do
      bogus_installed = backend.board_installed? "eggs:milk:wheat"
      expect(bogus_installed).to be false
      expect(bogus_installed).not_to be nil
    end
  end

  context "installation of boards" do
    it "installs and sets boards" do
      expect(backend.install_boards("arduino:sam")).to be true
    end
  end

  context "libraries" do
    it "knows where to find libraries" do
      fake_lib_name = "_____nope"
      expected_dir = Pathname.new(backend.lib_dir) + fake_lib_name
      fake_lib = backend.library_of_name(fake_lib_name)
      expect(fake_lib.path).to eq(expected_dir)
      expect(fake_lib.installed?).to be false
    end

    it "knows whether libraries exist in the manager" do
      expect(backend.library_available?("OneWire")).to be true

      # TODO: replace with a less offensive library name guaranteed never to exist?
      expect(backend.library_available?("fuck")).to be false
    end
  end

  context "board_manager" do
    it "Reads and writes board_manager URLs" do
      fake_urls = ["http://foo.bar", "http://arduino.ci"]
      existing_urls = backend.board_manager_urls

      # try to ensure maximum variability in the test
      test_url_sets = (existing_urls.empty? ? [fake_urls, []] : [[], fake_urls]) + [existing_urls]

      test_url_sets.each do |urls|
        backend.board_manager_urls = urls
        expect(backend.board_manager_urls).to match_array(urls)
      end
    end
  end


  context "compile_sketch" do

    sketch_path_ino = get_sketch("FakeSketch", "FakeSketch.ino")
    sketch_path_pde = get_sketch("FakeSketch", "FakeSketch.pde")
    sketch_path_mia = get_sketch("NO_FILE_HERE", "foo.ino")
    sketch_path_bad = get_sketch("BadSketch", "BadSketch.ino")

    it "Rejects a PDE sketch at #{sketch_path_pde}" do
      expect(backend.compile_sketch(sketch_path_pde, "arduino:avr:uno")).to be false
    end

    it "Fails a missing sketch at #{sketch_path_mia}" do
      expect(backend.compile_sketch(sketch_path_mia, "arduino:avr:uno")).to be false
    end

    it "Fails a bad sketch at #{sketch_path_bad}" do
      expect(backend.compile_sketch(sketch_path_bad, "arduino:avr:uno")).to be false
    end

    it "Passes a simple INO sketch at #{sketch_path_ino}" do
      expect(backend.compile_sketch(sketch_path_ino, "arduino:avr:uno")).to be true
    end

    it "Detects the bytes usage after compiling a sketch" do
      expect(backend.compile_sketch(sketch_path_ino, "arduino:avr:uno")).to be true
      the_bytes = backend.last_bytes_usage
      expect(the_bytes[:globals]).to eq 9
      expect(the_bytes[:free]).to eq 2039
      expect(the_bytes[:max]).to eq 2048
    end
  end

  context "--dry-run flags" do

    sketch_path_ino = get_sketch("FakeSketch", "FakeSketch.ino")

    before { allow(backend).to receive(:run_and_capture).and_call_original }

    it "Uses --dry-run flag for arduino-cli version < 0.14.0" do
      parsed_stdout = JSON.parse('{ "VersionString": "0.13.6" }')
      cli_version_output = {
        json: parsed_stdout
      }
      allow(backend).to receive(:capture_json).and_return cli_version_output

      backend.compile_sketch(sketch_path_ino, "arduino:avr:uno")

      expect(backend).to have_received(:run_and_capture).with(
        "compile",
        "--fqbn",
        "arduino:avr:uno",
        "--warnings",
        "all",
        "--dry-run",
        sketch_path_ino.to_s
      )
    end

    it "Does not use --dry-run flag for arduino-cli version >= 0.14.0" do
      parsed_stdout = JSON.parse('{ "VersionString": "0.14.0" }')
      cli_version_output = {
        json: parsed_stdout
      }
      allow(backend).to receive(:capture_json).and_return cli_version_output

      backend.compile_sketch(sketch_path_ino, "arduino:avr:uno")

      expect(backend).to have_received(:run_and_capture).with(
        "compile",
        "--fqbn",
        "arduino:avr:uno",
        "--warnings",
        "all",
        sketch_path_ino.to_s
      )
    end
  end
end
