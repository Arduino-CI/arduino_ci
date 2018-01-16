require 'fileutils'
require 'arduino_ci/display_manager'
require 'arduino_ci/arduino_installation'

module ArduinoCI

  # Wrap the Arduino executable.  This requires, in some cases, a faked display.
  class ArduinoCmd

    class << self
      protected :new

      # @return [ArduinoCmd] A command object with a best guess (or nil) for the installation
      def autolocate
        new(ArduinoInstallation.autolocate)
      end

      # @return [ArduinoCmd] A command object, installing Arduino if necessary
      def autolocate!
        new(ArduinoInstallation.autolocate!)
      end

    end

    attr_accessor :installation
    attr_reader   :prefs_response_time
    attr_reader   :library_is_indexed

    # @param installation [ArduinoInstallation] the location of the Arduino program installation
    def initialize(installation)
      @display_mgr         = DisplayManager::instance
      @installation        = installation
      @prefs_response_time = nil
      @prefs_cache         = nil
      @library_is_indexed  = false
    end

    def _parse_pref_string(arduino_output)
      lines = arduino_output.split("\n").select { |l| l.include? "=" }
      ret = lines.each_with_object({}) do |e, acc|
        parts = e.split("=", 2)
        acc[parts[0]] = parts[1]
        acc
      end
      ret
    end

    # fetch preferences to a hash
    def _prefs
      resp = nil
      if @installation.requires_x
        @display_mgr.with_display do
          start = Time.now
          resp = run_and_capture("--get-pref")
          @prefs_response_time = Time.now - start
        end
      else
        start = Time.now
        resp = run_and_capture("--get-pref")
        @prefs_response_time = Time.now - start
      end
      return nil unless resp[:success]
      _parse_pref_string(resp[:out])
    end

    def prefs
      @prefs_cache = _prefs if @prefs_cache.nil?
      @prefs_cache.clone
    end

    # get a preference key
    def get_pref(key)
      data = @prefs_cache.nil? ? prefs : @prefs_cache
      data[key]
    end

    # set a preference key/value pair
    # @param key [String] the preference key
    # @param value [String] the preference value
    # @return [bool] whether the command succeeded
    def set_pref(key, value)
      success = run_with_gui_guess(" about preferences", "--pref", "#{key}=#{value}", "--save-prefs")
      @prefs_cache[key] = value if success
      success
    end

    # run the arduino command
    def run(*args, **kwargs)
      full_args = @installation.base_cmd + args
      if @installation.requires_x
        @display_mgr.run(*full_args, **kwargs)
      else
        Host.run(*full_args, **kwargs)
      end
    end

    def run_with_gui_guess(message, *args, **kwargs)
      # On Travis CI, we get an error message in the GUI instead of on STDERR
      # so, assume that if we don't get a rapid reply that things are not installed

      # if we don't need X, we can skip this whole thing
      return run_and_capture(*args, **kwargs)[:success] unless @installation.requires_x

      prefs if @prefs_response_time.nil?
      x3 = @prefs_response_time * 3
      Timeout.timeout(x3) do
        result = run_and_capture(*args, **kwargs)
        result[:success]
      end
    rescue Timeout::Error
      puts "No response in #{x3} seconds. Assuming graphical modal error message#{message}."
      false
    end

    # run a command and capture its output
    # @return [Hash] {:out => String, :err => String, :success => bool}
    def run_and_capture(*args, **kwargs)
      pipe_out, pipe_out_wr = IO.pipe
      pipe_err, pipe_err_wr = IO.pipe
      our_kwargs = { out: pipe_out_wr, err: pipe_err_wr }
      eventual_kwargs = our_kwargs.merge(kwargs)
      success = run(*args, **eventual_kwargs)
      pipe_out_wr.close
      pipe_err_wr.close
      str_out = pipe_out.read
      str_err = pipe_err.read
      pipe_out.close
      pipe_err.close
      { out: str_out, err: str_err, success: success }
    end

    # run a command and don't capture its output, but use the same signature
    # @return [Hash] {:out => String, :err => String, :success => bool}
    def run_wrap(*args, **kwargs)
      success = run(*args, **kwargs)
      { out: "NOPE, use run_and_capture", err: "NOPE, use run_and_capture", success: success }
    end

    # check whether a board is installed
    # we do this by just selecting a board.
    #   the arduino binary will error if unrecognized and do a successful no-op if it's installed
    def board_installed?(boardname)
      run_with_gui_guess(" about board not installed", "--board", boardname)
    end

    # install a board by name
    # @param name [String] the board name
    # @return [bool] whether the command succeeded
    def install_board(boardname)
      # TODO: find out why IO.pipe fails but File::NULL succeeds :(
      run_and_capture("--install-boards", boardname, out: File::NULL)[:success]
    end

    # install a library by name
    # @param name [String] the library name
    # @return [bool] whether the command succeeded
    def install_library(library_name)
      result = run_and_capture("--install-library", library_name)
      @library_is_indexed = true if result[:success]
      result[:success]
    end

    # generate the (very likely) path of a library given its name
    def library_path(library_name)
      sketchbook = get_pref("sketchbook.path")
      File.join(sketchbook, library_name)
    end

    # update the library index
    def update_library_index
      # install random lib so the arduino IDE grabs a new library index
      # see: https://github.com/arduino/Arduino/issues/3535
      install_library("USBHost")
    end

    # use a particular board for compilation
    def use_board(boardname)
      run_with_gui_guess(" about board not installed", "--board", boardname, "--save-prefs")
    end

    # use a particular board for compilation, installing it if necessary
    def use_board!(boardname)
      return true if use_board(boardname)
      boardfamily = boardname.split(":")[0..1].join(":")
      puts "Board '#{boardname}' not found; attempting to install '#{boardfamily}'"
      return false unless install_board(boardfamily) # guess board family from first 2 :-separated fields
      use_board(boardname)
    end

    def verify_sketch(path)
      ext = File.extname path
      unless ext.casecmp(".ino").zero?
        puts "Refusing to verify sketch with '#{ext}' extension -- rename it to '.ino'!"
        return false
      end
      unless File.exist? path
        puts "Can't verify nonexistent Sketch at '#{path}'!"
        return false
      end
      run("--verify", path, err: :out)
    end

    # ensure that the given library is installed, or symlinked as appropriate
    # return the path of the prepared library, or nil
    def install_local_library(library_path)
      library_name = File.basename(library_path)
      destination_path = File.join(@installation.lib_dir, library_name)

      # things get weird if the sketchbook contains the library.
      # check that first
      if File.exist? destination_path
        uhoh = "There is already a library '#{library_name}' in the library directory"
        return destination_path if destination_path == library_path

        # maybe it's a symlink? that would be OK
        if File.symlink?(destination_path)
          return destination_path if File.readlink(destination_path) == library_path
          puts "#{uhoh} and it's not symlinked to #{library_path}"
          return nil
        end

        puts "#{uhoh}.  It may need to be removed manually."
        return nil
      end

      # install the library
      FileUtils.ln_s(library_path, destination_path)
      destination_path
    end

    def each_library_example(installed_library_path)
      example_path = File.join(installed_library_path, "examples")
      examples = Pathname.new(example_path).children.select(&:directory?).map(&:to_path).map(&File.method(:basename))
      examples.each do |e|
        proj_file = File.join(example_path, e, "#{e}.ino")
        puts "Considering #{proj_file}"
        yield proj_file if File.exist?(proj_file)
      end
    end
  end
end
