require 'fileutils'

module ArduinoCI

  # Wrap the Arduino executable.  This requires, in some cases, a faked display.
  class ArduinoCmd

    # Enable a shortcut syntax for command line flags
    # @param name [String] What the flag will be called (prefixed with 'flag_')
    # @return [void]
    # @macro [attach] flag
    #   @!attribute [r] flag_$1
    #   @return String $2 the text of the command line flag
    def self.flag(name, text = nil)
      text = "(flag #{name} not defined)" if text.nil?
      self.class_eval("def flag_#{name};\"#{text}\";end")
    end

    attr_accessor :installation
    attr_accessor :base_cmd

    attr_reader   :library_is_indexed

    # set the command line flags (undefined for now).
    # These vary between gui/cli
    flag :get_pref
    flag :set_pref
    flag :save_prefs
    flag :use_board
    flag :install_boards
    flag :install_library
    flag :verify

    def initialize
      @prefs_cache         = nil
      @library_is_indexed  = false
    end

    def parse_pref_string(arduino_output)
      lines = arduino_output.split("\n").select { |l| l.include? "=" }
      ret = lines.each_with_object({}) do |e, acc|
        parts = e.split("=", 2)
        acc[parts[0]] = parts[1]
        acc
      end
      ret
    end

    def _lib_dir
      "<lib dir not defined>"
    end

    # fetch preferences to a string
    def _prefs_raw
      resp = run_and_capture(flag_get_pref)
      return nil unless resp[:success]
      resp[:out]
    end

    def prefs
      prefs_raw = _prefs_raw if @prefs_cache.nil?
      return nil if prefs_raw.nil?
      @prefs_cache = parse_pref_string(prefs_raw)
      @prefs_cache.clone
    end

    # get a preference key
    def get_pref(key)
      data = @prefs_cache.nil? ? prefs : @prefs_cache
      data[key]
    end

    # underlying preference-setter.
    # @return [bool] whether the command succeeded
    def _set_pref(key, value)
      run_and_capture(flag_set_pref, "#{key}=#{value}", flag_save_prefs)[:success]
    end

    # set a preference key/value pair, and update the cache.
    # @param key [String] the preference key
    # @param value [String] the preference value
    # @return [bool] whether the command succeeded
    def set_pref(key, value)
      success = _set_pref(key, value)
      @prefs_cache[key] = value if success
      success
    end

    # run the arduino command
    def run(*args, **kwargs)
      raise "Ian needs to implement this in a subclass #{args} #{kwargs}"
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
      run_and_capture(flag_use_board, boardname)[:success]
    end

    # install a board by name
    # @param name [String] the board name
    # @return [bool] whether the command succeeded
    def install_board(boardname)
      # TODO: find out why IO.pipe fails but File::NULL succeeds :(
      run_and_capture(flag_install_boards, boardname, out: File::NULL)[:success]
    end

    # install a library by name
    # @param name [String] the library name
    # @return [bool] whether the command succeeded
    def install_library(library_name)
      result = run_and_capture(flag_install_library, library_name)
      @library_is_indexed = true if result[:success]
      result[:success]
    end

    # generate the (very likely) path of a library given its name
    def library_path(library_name)
      File.join(_lib_dir, library_name)
    end

    # update the library index
    def update_library_index
      # install random lib so the arduino IDE grabs a new library index
      # see: https://github.com/arduino/Arduino/issues/3535
      install_library("USBHost")
    end

    # use a particular board for compilation
    def use_board(boardname)
      run_and_capture(flag_use_board, boardname, flag_save_prefs)[:success]
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
      run(flag_verify, path, err: :out)
    end

    # ensure that the given library is installed, or symlinked as appropriate
    # return the path of the prepared library, or nil
    def install_local_library(path)
      library_name = File.basename(path)
      destination_path = library_path(library_name)

      # things get weird if the sketchbook contains the library.
      # check that first
      if File.exist? destination_path
        uhoh = "There is already a library '#{library_name}' in the library directory"
        return destination_path if destination_path == path

        # maybe it's a symlink? that would be OK
        if File.symlink?(destination_path)
          return destination_path if File.readlink(destination_path) == path
          puts "#{uhoh} and it's not symlinked to #{path}"
          return nil
        end

        puts "#{uhoh}.  It may need to be removed manually."
        return nil
      end

      # install the library
      FileUtils.ln_s(path, destination_path)
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
