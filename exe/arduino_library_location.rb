#!/usr/bin/env ruby
require 'arduino_ci'

# locate and/or forcibly install Arduino, keep stdout clean
@arduino_backend = ArduinoCI::ArduinoInstallation.autolocate!($stderr)

puts @arduino_backend.lib_dir
