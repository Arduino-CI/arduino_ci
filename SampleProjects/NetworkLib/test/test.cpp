/*
cd SampleProjects/Ethernet 
bundle config --local path vendor/bundle
bundle install
bundle exec arduino_ci_remote.rb  --skip-compilation
# bundle exec arduino_ci_remote.rb  --skip-examples-compilation
*/

#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(test) {
  assertTrue(true);
}

unittest_main()
