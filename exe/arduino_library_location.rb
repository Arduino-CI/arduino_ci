#!/usr/bin/env ruby
require 'arduino_ci'

# locate and/or forcibly install Arduino, keep stdout clean
@arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!($stderr)

puts @arduino_cmd.lib_dir
