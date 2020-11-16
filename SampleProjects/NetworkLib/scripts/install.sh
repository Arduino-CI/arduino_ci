#!/bin/bash

# if we don't have an Ethernet library already (say, in new install or for an automated test),
# then get the custom one we want to use for testing
cd $(bundle exec arduino_library_location.rb)
if [ ! -d ./Ethernet ] ; then
  git clone --depth 1 https://github.com/Arduino-CI/Ethernet.git
fi
