/*
cd SampleProjects/NetworkLib
bundle config --local path vendor/bundle
bundle install
bundle exec arduino_ci_remote.rb  --skip-compilation
# bundle exec arduino_ci_remote.rb  --skip-examples-compilation
*/

#include <Arduino.h>
#include <ArduinoUnitTests.h>
#include <Ethernet.h>

unittest(test) { assertEqual(EthernetNoHardware, Ethernet.hardwareStatus()); }

unittest_main()
