require "arduino_ci"

class FakeLibDir

  attr_reader :config_dir
  attr_reader :config_file
  attr_reader :backend
  attr_reader :arduino_dir
  attr_reader :libraries_dir

  def initialize
    # we will need to install some dummy libraries into a fake location, so do that on demand
    @config_dir = Pathname.new(Dir.pwd).realpath
    @config_file = @config_dir + ArduinoCI::ArduinoBackend::CONFIG_FILE_NAME
    @backend = ArduinoCI::ArduinoInstallation.autolocate!
    @backend.config_dir = @config_dir
  end

  # designed to be called by rspec's "around" function
  def in_pristine_fake_libraries_dir(example)
    d = Dir.mktmpdir
    begin
      # write a yaml file containing the current directory
      dummy_config = { "directories" => { "user" => d.to_s } }
      @arduino_dir = Pathname.new(d)
      @libraries_dir = @arduino_dir + "libraries"
      Dir.mkdir(@libraries_dir)

      f = File.open(@config_file, "w")
      begin
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
    ensure
      if ArduinoCI::Host.needs_symlink_hack?
        stdout, stderr, exitstatus = Open3.capture3('cmd.exe', "/c rmdir /s /q #{ArduinoCI::Host.pathname_to_windows(d)}")
        unless exitstatus.success?
          puts "====== rmdir of #{d} failed"
          puts stdout
          puts stderr
        end
      else
        FileUtils.remove_entry(d)
      end
    end
  end


end
