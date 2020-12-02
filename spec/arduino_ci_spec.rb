require "spec_helper"

RSpec.describe ArduinoCI do
  next if skip_ruby_tests
  context "gem" do
    it "has a version number" do
      expect(ArduinoCI::VERSION).not_to be nil
    end
  end
end
