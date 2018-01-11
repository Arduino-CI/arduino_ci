require "spec_helper"

RSpec.describe ArduinoCI do
  context "gem" do
    it "has a version number" do
      expect(ArduinoCI::VERSION).not_to be nil
    end
  end
end

RSpec.describe ArduinoCI::Host do
  context "which" do
    it "can find things with which" do
      ruby_path = ArduinoCI::Host.which("ruby")
      expect(ruby_path).not_to be nil
      expect(ruby_path.include? "ruby").to be true
    end
  end

end
