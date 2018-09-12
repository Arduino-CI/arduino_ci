require 'os'
require 'open3'
require 'pathname'

module ArduinoCI

  # Tools for interacting with the host machine
  class Host
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

    # if on windows, call mklink, else self.symlink
    # https://stackoverflow.com/a/22716582/2063546
    def self.symlink(old_path, new_path)
      return FileUtils.ln_s(old_path, new_path) unless RUBY_PLATFORM =~ /mswin32|cygwin|mingw|bccwin/

      # windows mklink syntax is reverse of unix ln -s
      # windows mklink is built into cmd.exe
      # vulnerable to command injection, but okay because this is a hack to make a cli tool work.
      _stdin, _stdout, _stderr, wait_thr = Open3.popen3('cmd.exe', "/c mklink #{new_path} #{old_path}")
      wait_thr.value.exitstatus
    end
  end
end
