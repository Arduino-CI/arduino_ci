require 'os'

module ArduinoCI

  # Tools for interacting with the host machine
  class Host
    # Cross-platform way of finding an executable in the $PATH.
    # via https://stackoverflow.com/a/5471032/2063546
    #   which('ruby') #=> /usr/bin/ruby
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
      # do some work to extract & merge environment variables if they exist
      has_env = !args.empty? && args[0].class == Hash
      env_vars = has_env ? args[0] : {}
      actual_args = has_env ? args[1..-1] : args  # need to shift over if we extracted args
      full_cmd = env_vars.empty? ? actual_args : [env_vars] + actual_args
      shell_vars = env_vars.map { |k, v| "#{k}=#{v}" }.join(" ")
      puts " $ #{shell_vars} #{actual_args.join(' ')}"
      ret = system(*full_cmd, **kwargs)
      status = ret ? "succeeded" : "failed"
      puts "Command '#{File.basename(actual_args[0])}' has #{status}"
      ret
    end

    def self.os
      return :osx if OS.osx?
      return :linux if OS.linux?
      return :windows if OS.windows?
    end

  end
end
