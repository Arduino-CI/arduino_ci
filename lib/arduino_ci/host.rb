require 'os'

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

    # run a command in a display
    def self.run(*args, **kwargs)
      system(*args, **kwargs)
    end

    # return [Symbol] the operating system of the host
    def self.os
      return :osx if OS.osx?
      return :linux if OS.linux?
      return :windows if OS.windows?
    end

  end
end
