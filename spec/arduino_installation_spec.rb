require "spec_helper"
require "pathname"
require "tmpdir"
require "os"

# test function for below, to avoid long lines
def bug_753_cmd(backend, config_file)
  [
    backend.binary_path.to_s,
    "--config-file",
    config_file.to_s,
    "--verbose",
    "config",
    "dump"
  ]
end

def with_tmp_file(desired_filename = nil)
  Dir.mktmpdir do |tdir|
    config_dir = Pathname(tdir)
    config_file = config_dir + (desired_filename || ArduinoCI::ArduinoBackend::CONFIG_FILE_NAME)
    File.open(config_file, "w") { |f| f.write("") }
    yield(config_dir, config_file)
  end
end

def config_success_msg(config_file)
  config_file_str = config_file.to_s
  config_file_str = config_file_str.gsub('/', '\\') if OS.windows?
  "Using config file: #{config_file}"
end

def config_fail_msg
  "Config file not found, using default values"
end

RSpec.describe ArduinoCI::ArduinoInstallation do
  next if skip_ruby_tests

  context "constants" do
    it "Exposes desired backend version" do
      expect(ArduinoCI::ArduinoInstallation::DESIRED_ARDUINO_CLI_VERSION).to eq("0.13.0")
    end
  end

  context "autolocate" do
    it "doesn't fail" do
      ArduinoCI::ArduinoInstallation.autolocate
    end
  end

  context "autolocate!" do
    backend = ArduinoCI::ArduinoInstallation.autolocate!
    it "doesn't fail" do
      expect(backend.binary_path).not_to be nil
      expect(backend.lib_dir).not_to be nil
    end
  end

  context "force_install" do
    it "Can redirect output" do
      output = StringIO.new
      output.rewind
      expect(output.read.empty?).to be true
      # install a bogus version to save time downloading
      backend = ArduinoCI::ArduinoInstallation.force_install(output, "BOGUS VERSION")
      output.rewind
      expect(output.read.empty?).to be false
    end
  end

  context "installed version-specific quirks" do
    backend = ArduinoCI::ArduinoInstallation.autolocate!

    #  https://github.com/arduino/arduino-cli/issues/753

    it "suffers from arduino-cli bug 753 - nonstandard filename" do
      # foo.yml won't be accepted as a filename
      with_tmp_file("foo.yml") do |config_dir, config_file|
        expect(config_dir).to exist
        expect(config_file).to exist
        ret = ArduinoCI::Host.run_and_capture(*bug_753_cmd(backend, config_file))
        if OS.linux?
          expect(ret[:out].lines[0]).to include(config_success_msg(config_file))
        else
          expect(ret[:out].lines[0]).to include(config_fail_msg)
        end
      end
    end

    it "obeys arduino-cli bug 753 workaround" do
      # the standard filename will work
      with_tmp_file do |config_dir, config_file|
        expect(config_dir).to exist
        expect(config_file).to exist
        ret = ArduinoCI::Host.run_and_capture(*bug_753_cmd(backend, config_file))
        expect(ret[:out].lines[0]).to include(config_success_msg(config_file))
      end
    end

    it "obeys arduino-cli bug 753" do
      # the directory alone will work if there is a file with the right name
      with_tmp_file do |config_dir, config_file|
        expect(config_dir).to exist
        expect(config_file).to exist
        ret = ArduinoCI::Host.run_and_capture(*bug_753_cmd(backend, config_dir))
        if OS.linux?
          expect(ret[:out].lines[0]).to include(config_fail_msg)
        else
          expect(ret[:out].lines[0]).to include(config_success_msg(config_file))
        end
      end
    end
  end

end
