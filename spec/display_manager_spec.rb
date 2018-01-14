require "spec_helper"

RSpec.describe ArduinoCI::DisplayManager do
  context "singleton ::instance" do
    it "produces an instance" do
      expect(ArduinoCI::DisplayManager::instance).not_to be_nil
    end
  end

  context "with_display" do
    manager = ArduinoCI::DisplayManager::instance
    manager.disable

    it "Properly enables and disables when not previously enabled" do
      expect(manager.enabled).to be false
      manager.with_display do |environment|
        expect(manager.enabled).to be true
        expect(environment.class).to eq(Hash)
        also_manager = ArduinoCI::DisplayManager::instance
        expect(also_manager.enabled).to be true
      end
      expect(manager.enabled).to be false
    end

    it "Properly enables and disables when previously enabled" do
      manager.enable
      expect(manager.enabled).to be true
      manager.with_display do |environment|
        expect(manager.enabled).to be true
        expect(environment.class).to eq(Hash)
        also_manager = ArduinoCI::DisplayManager::instance
        expect(also_manager.enabled).to be true
      end
      expect(manager.enabled).to be true
    end
  end
end
