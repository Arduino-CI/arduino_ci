#!/usr/bin/env ruby
require 'arduino_ci'

# this will exit after Arduino is located and/or forcibly installed
ArduinoCI::ArduinoInstallation.autolocate!
