/*
bundle config --local path vendor/bundle
bundle install
bundle exec arduino_ci.rb --skip-examples-compilation
*/

#include <Arduino.h>
#include <ArduinoUnitTests.h>
#include <BusIO.h>

unittest(loop) {
  // token test
  BusIO busIO;
  assertEqual(42, busIO.answer()));
}

unittest_main()
