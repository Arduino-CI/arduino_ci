#!/bin/bash
echo "arduino_ci.rb is eprecated in favor of arduino_ci.rb."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
$DIR/arduino_ci.rb "$@"
