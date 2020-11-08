#!/bin/bash

# if we don't have an Ethernet library, then get the standard one
cd $(bundle exec arduino_library_location.rb)
if [ ! -d ./Ethernet ] ; then
  git clone https://github.com/arduino-libraries/Ethernet.git
fi
