#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
cd ../src
rm -rf Ethernet > /dev/null 2>&1
# get Ethernet library
git clone https://github.com/arduino-libraries/Ethernet.git
