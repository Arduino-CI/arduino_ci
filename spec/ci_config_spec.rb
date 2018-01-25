require "spec_helper"

RSpec.describe ArduinoCI::CIConfig do
  context "default" do
    it "loads from yaml" do
      default_config = ArduinoCI::CIConfig.default
      expect(default_config).not_to be nil
      uno = default_config.platform_definition("uno")
      expect(uno.class).to eq(Hash)
      expect(uno[:board]).to eq("arduino:avr:uno")
      expect(uno[:package]).to be nil
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

      expect(default_config.package_url("adafruit:avr")).to eq("https://adafruit.github.io/arduino-board-index/package_adafruit_index.json")
      expect(default_config.platforms_to_build).to match(["uno", "due", "zero", "leonardo"])
      expect(default_config.platforms_to_unittest).to match(["uno", "due", "zero", "leonardo"])
      expect(default_config.aux_libraries_for_build).to match([])
      expect(default_config.aux_libraries_for_unittest).to match([])
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
      expect(uno[:package]).to be nil
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

end

