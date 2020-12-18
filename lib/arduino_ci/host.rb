require 'os'
require 'open3'
require 'pathname'

module ArduinoCI

  # Tools for interacting with the host machine
  class Host
    # TODO: this came from https://stackoverflow.com/a/22716582/2063546
    #       and I'm not sure if it can be replaced by self.os == :windows
    WINDOWS_VARIANT_REGEX = /mswin32|cygwin|mingw|bccwin/.freeze

    # e.g. 11/27/2020  01:02 AM    <SYMLINKD>     ExcludeSomething [C:\projects\arduino-ci\SampleProjects\ExcludeSomething]
    DIR_SYMLINK_REGEX = %r{\d+/\d+/\d+\s+[^<]+<SYMLINKD?>\s+(.*) \[([^\]]+)\]}.freeze

    # Cross-platform way of finding an executable in the $PATH.
    # via https://stackoverflow.com/a/5471032/2063546
    #   which('ruby') #=> /usr/bin/ruby
    # @param cmd [String] the command to search for
    # @return [String] the full path to the command if it exists
    def self.which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end

    def self.run_and_capture(*args, **kwargs)
      stdout, stderr, status = Open3.capture3(*args, **kwargs)
      { out: stdout, err: stderr, success: status.exitstatus.zero? }
    end

    def self.run_and_output(*args, **kwargs)
      system(*args, **kwargs)
    end

    # return [Symbol] the operating system of the host
    def self.os
      return :osx if OS.osx?
      return :linux if OS.linux?
      return :windows if OS.windows?
    end

    # Cross-platform symlinking
    # if on windows, call mklink, else self.symlink
    # @param [Pathname] old_path
    # @param [Pathname] new_path
    def self.symlink(old_path, new_path)
      # we would prefer `new_path.make_symlink(old_path)` but "symlink function is unimplemented on this machine" with windows
      return new_path.make_symlink(old_path) unless needs_symlink_hack?

      # via https://stackoverflow.com/a/22716582/2063546
      # windows mklink syntax is reverse of unix ln -s
      # windows mklink is built into cmd.exe
      # vulnerable to command injection, but okay because this is a hack to make a cli tool work.
      orp = pathname_to_windows(old_path.realpath)
      np  = pathname_to_windows(new_path)

      _stdout, _stderr, exitstatus = Open3.capture3('cmd.exe', "/C mklink /D #{np} #{orp}")
      exitstatus.success?
    end

    # Hack for "realpath" which on windows joins paths with slashes instead of backslashes
    # @param path [Pathname] the path to render
    # @return [String] A path that will work on windows
    def self.pathname_to_windows(path)
      path.to_s.tr("/", "\\")
    end

    # Hack for "realpath" which on windows joins paths with slashes instead of backslashes
    # @param str [String] the windows path
    # @return [Pathname] A path that will be recognized by pathname
    def self.windows_to_pathname(str)
      Pathname.new(str.tr("\\", "/"))
    end

    # Whether this OS requires a hack for symlinks
    # @return [bool]
    def self.needs_symlink_hack?
      RUBY_PLATFORM =~ WINDOWS_VARIANT_REGEX
    end

    # Cross-platform is-this-a-symlink function
    # @param [Pathname] path
    # @return [bool] Whether the file is a symlink
    def self.symlink?(path)
      return path.symlink? unless needs_symlink_hack?

      !readlink(path).nil?
    end

    # Cross-platform "read link" function
    # @param [Pathname] path
    # @return [Pathname] the link target
    def self.readlink(path)
      return path.readlink unless needs_symlink_hack?

      the_dir  = pathname_to_windows(path.parent)
      the_file = path.basename.to_s

      stdout, _stderr, _exitstatus = Open3.capture3('cmd.exe', "/c dir /al #{the_dir}")
      symlinks = stdout.lines.map { |l| DIR_SYMLINK_REGEX.match(l.scrub) }.compact
      our_link = symlinks.find { |m| m[1] == the_file }
      return nil if our_link.nil?

      windows_to_pathname(our_link[2])
    end
  end
end
