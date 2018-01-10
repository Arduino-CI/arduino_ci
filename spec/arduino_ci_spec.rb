require "spec_helper"

RSpec.describe ArduinoCI do
  it "has a version number" do
    expect(ArduinoCI::VERSION).not_to be nil
  end
end
