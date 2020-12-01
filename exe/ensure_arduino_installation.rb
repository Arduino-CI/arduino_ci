#!/usr/bin/env ruby
require 'arduino_ci'

# this will exit after Arduino is located and/or forcibly installed
backend = ArduinoCI::ArduinoInstallation.autolocate!
lib_dir = backend.lib_dir

unless lib_dir.exist?
  puts "Creating libraries directory #{lib_dir}"
  lib_dir.mkpath
end
