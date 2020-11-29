#!/usr/bin/env ruby
require 'arduino_ci'

# locate and/or forcibly install Arduino, keep stdout clean
@backend = ArduinoCI::ArduinoInstallation.autolocate!($stderr)

puts @backend.lib_dir
