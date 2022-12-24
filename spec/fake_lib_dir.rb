require "arduino_ci"

# This class is meant for the :around behavior of RSpec test cases so that
# we can make temporary directories in test cases. Note that since test cases
# are evaluated on load, any temp directories that were created will not exist
# by the time the test runs.  So this class handles all of the particulars
# around creating a fake library directory on time and configuring the backend
# to properly use it.
class FakeLibDir

  attr_reader :config_dir
  attr_reader :config_file
  attr_reader :backend
  attr_reader :arduino_dir
  attr_reader :libraries_dir

  def initialize
    # we will need to install some dummy libraries into a fake location, so do that on demand
    @config_dir = Pathname.new(Dir.pwd).realpath
    @config_file = ArduinoCI::ArduinoBackend.config_file_path_from_dir(@config_dir)
    @backend = ArduinoCI::ArduinoInstallation.autolocate!
    @backend.config_file_path = @config_file
  end

  # designed to be called by rspec's "around" function
  def in_pristine_fake_libraries_dir(example)
    # we will make a dummy directory to contain the libraries directory,
    # and use that directory in a dummy config which we will pass to the backend.
    # then we can run the test case
    Dir.mktmpdir do |d|
      # write a yaml file containing the current directory
      dummy_config = { "directories" => { "user" => d.to_s } }
      @arduino_dir = Pathname.new(d)
      @libraries_dir = @arduino_dir + "libraries"
      Dir.mkdir(@libraries_dir)

      # with the config file, enforce a structure similar to a temp file -- delete after use
      File.open(@config_file, "w") do |f|
        f.write dummy_config.to_yaml
        f.close
        example.run
      ensure
        begin
          File.unlink(@config_file)
        rescue Errno::ENOENT
          # cool, already done
        end
      end
    end
  end
end
