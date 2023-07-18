/*
cd SampleProjects/Makefile
bundle config --local path vendor/bundle
bundle install
bundle exec arduino_ci.rb --skip-examples-compilation
*/

#include <Arduino.h>
#include <ArduinoUnitTests.h>

unittest(test) { assertEqual(true, true); }

unittest_main()
