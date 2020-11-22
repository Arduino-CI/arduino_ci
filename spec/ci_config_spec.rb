require "spec_helper"
require "pathname"

require "fake_lib_dir"

RSpec.describe ArduinoCI::CIConfig do
  next if skip_ruby_tests
  context "default" do
    it "loads from yaml" do
      default_config = ArduinoCI::CIConfig.default
      expect(default_config).not_to be nil
      uno = default_config.platform_definition("uno")
      expect(uno.class).to eq(Hash)
      expect(uno[:board]).to eq("arduino:avr:uno")
      expect(uno[:package]).to eq("arduino:avr")
      expect(uno[:gcc].class).to eq(Hash)

      due = default_config.platform_definition("due")
      expect(due.class).to eq(Hash)
      expect(due[:board]).to eq("arduino:sam:arduino_due_x")
      expect(due[:package]).to eq("arduino:sam")
      expect(due[:gcc].class).to eq(Hash)

      zero = default_config.platform_definition("zero")
      expect(zero.class).to eq(Hash)
      expect(zero[:board]).to eq("arduino:samd:arduino_zero_native")
      expect(zero[:package]).to eq("arduino:samd")
      expect(zero[:gcc].class).to eq(Hash)

      expect(default_config.package_builtin?("arduino:avr")).to be true
      expect(default_config.package_builtin?("adafruit:avr")).to be false

      expect(default_config.package_url("adafruit:avr")).to eq("https://adafruit.github.io/arduino-board-index/package_adafruit_index.json")
      expect(default_config.package_url("adafruit:samd")).to eq("https://adafruit.github.io/arduino-board-index/package_adafruit_index.json")
      expect(default_config.package_url("esp32:esp32")).to eq("https://dl.espressif.com/dl/package_esp32_index.json")
      expect(default_config.platforms_to_build).to match(["uno", "due", "zero", "leonardo", "m4", "esp32", "esp8266", "mega2560"])
      expect(default_config.platforms_to_unittest).to match(["uno", "due", "zero", "leonardo"])
      expect(default_config.aux_libraries_for_build).to match([])
      expect(default_config.aux_libraries_for_unittest).to match([])

      expect(default_config.compilers_to_use).to match(["g++"])
    end
  end

  context "clone" do
    it "creates a copy" do
      base = ArduinoCI::CIConfig.new
      base.load_yaml(File.join(File.dirname(__FILE__), "yaml", "o2.yaml"))

      expect(base.to_h).to eq(
        packages: {},
        platforms: {
          "bogo"=> {
            board: "fakeduino:beep:bogo"
          },
        },
        compile: {
          libraries: ["zip"],
          platforms: ["bogo"]
        },
        unittest: {
          testfiles: {
            select: ["*-*.*"],
            reject: ["sam-squamsh.*"]
          },
          libraries: ["def456"],
          platforms: ["bogo"]
        }
      )
    end
  end

  context "clone" do
    it "creates a copy" do
      base = ArduinoCI::CIConfig.default
      orig = base.to_h
      clone1 = orig.clone.to_h
      clone2 = orig.clone.to_h

      expect(orig).to eq(clone1)
      expect(clone1).to eq(clone2)
    end
  end

  context "with_override" do
    it "loads from yaml" do
      override_file = File.join(File.dirname(__FILE__), "yaml", "o1.yaml")
      combined_config = ArduinoCI::CIConfig.default.with_override(override_file)
      expect(combined_config).not_to be nil
      uno = combined_config.platform_definition("uno")
      expect(uno.class).to eq(Hash)
      expect(uno[:board]).to eq("arduino:avr:uno")
      expect(uno[:package]).to eq("arduino:avr")
      expect(uno[:gcc].class).to eq(Hash)

      zero = combined_config.platform_definition("zero")
      expect(zero).to be nil

      esp = combined_config.platform_definition("esp8266")
      expect(esp[:board]).to eq("esp8266:esp8266:booo")
      expect(esp[:package]).to eq("esp8266:esp8266")

      bogo = combined_config.platform_definition("bogo")
      expect(bogo.class).to eq(Hash)
      expect(bogo[:package]).to eq("potato:salad")
      expect(bogo[:gcc].class).to eq(Hash)
      expect(bogo[:gcc][:features]).to match(["a", "b"])
      expect(bogo[:gcc][:defines]).to match(["c", "d"])
      expect(bogo[:gcc][:warnings]).to match(["e", "f"])
      expect(bogo[:gcc][:flags]).to match(["g", "h"])

      expect(combined_config.package_url("adafruit:avr")).to eq("https://adafruit.github.io/arduino-board-index/package_adafruit_index.json")
      expect(combined_config.platforms_to_build).to match(["esp8266"])
      expect(combined_config.platforms_to_unittest).to match(["bogo"])
      expect(combined_config.aux_libraries_for_build).to match(["Adafruit FONA Library"])
      expect(combined_config.aux_libraries_for_unittest).to match(["abc123", "def456"])

      expect(combined_config.compilers_to_use).to match(["g++", "g++-7"])

    end
  end

  context "with_config" do
    it "loads from yaml" do
      override_dir = File.join(File.dirname(__FILE__), "yaml", "override1")
      base_config = ArduinoCI::CIConfig.default
      combined_config = base_config.from_example(override_dir)

      expect(combined_config).not_to be nil
      uno = combined_config.platform_definition("uno")
      expect(uno.class).to eq(Hash)
      expect(uno[:board]).to eq("arduino:avr:uno")
      expect(uno[:package]).to eq("arduino:avr")
      expect(uno[:gcc].class).to eq(Hash)

      zero = combined_config.platform_definition("zero")
      expect(zero).to be nil

      esp = combined_config.platform_definition("esp8266")
      expect(esp[:board]).to eq("esp8266:esp8266:booo")
      expect(esp[:package]).to eq("esp8266:esp8266")

      bogo = combined_config.platform_definition("bogo")
      expect(bogo.class).to eq(Hash)
      expect(bogo[:package]).to eq("potato:salad")
      expect(bogo[:gcc].class).to eq(Hash)
      expect(bogo[:gcc][:features]).to match(["a", "b"])
      expect(bogo[:gcc][:defines]).to match(["c", "d"])
      expect(bogo[:gcc][:warnings]).to match(["e", "f"])
      expect(bogo[:gcc][:flags]).to match(["g", "h"])

      expect(combined_config.package_url("adafruit:avr")).to eq("https://adafruit.github.io/arduino-board-index/package_adafruit_index.json")
      expect(combined_config.platforms_to_build).to match(["esp8266"])
      expect(combined_config.platforms_to_unittest).to match(["bogo"])
      expect(combined_config.aux_libraries_for_build).to match(["Adafruit FONA Library"])
      expect(combined_config.aux_libraries_for_unittest).to match(["abc123", "def456"])
    end
  end

  context "allowable_unittest_files" do

    # we will need to install some dummy libraries into a fake location, so do that on demand
    fld = FakeLibDir.new
    backend = fld.backend
    cpp_lib_path = Pathname.new(__dir__) + "fake_library"

    around(:example) { |example| fld.in_pristine_fake_libraries_dir(example) }
    before(:each) { @cpp_library = backend.install_local_library(cpp_lib_path) }

    it "starts with a known set of files" do
      expect(cpp_lib_path.exist?).to be(true)
      expect(@cpp_library).to_not be(nil)
      expect(@cpp_library.path.exist?).to be(true)
      expect(@cpp_library.test_files.map { |f| File.basename(f) }).to match_array([
        "sam-squamsh.cpp",
        "yes-good.cpp",
        "mars.cpp"
      ])
    end

    it "filters that set of files" do
      override_file = File.join(File.dirname(__FILE__), "yaml", "o1.yaml")
      combined_config = ArduinoCI::CIConfig.default.with_override(override_file)
      expect(combined_config.allowable_unittest_files(@cpp_library.test_files).map { |f| File.basename(f) }).to match_array([
        "yes-good.cpp",
      ])
    end
  end

end
