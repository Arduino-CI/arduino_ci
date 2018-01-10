require "spec_helper"

RSpec.describe ArduinoCI::DisplayManager do
  context "singleton ::instance" do
    it "produces an instance" do
      expect(ArduinoCI::DisplayManager::instance).not_to be_nil
    end
  end

  context "with_display" do
    it "Properly enables and disables" do
      manager = ArduinoCI::DisplayManager::instance
      expect(manager.enabled).to be false
      manager.with_display do |environment|
        expect(manager.enabled).to be true
        expect(environment.class).to eq(Hash)
        also_manager = ArduinoCI::DisplayManager::instance
        expect(also_manager.enabled).to be true
      end
      expect(manager.enabled).to be false
    end
  end
end
