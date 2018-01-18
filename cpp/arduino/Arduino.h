/*
Mock Arduino.h library.

Where possible, variable names from the Arduino library are used to avoid conflicts

*/


#ifndef ARDUINO_CI_ARDUINO

#include "math.h"
#define ARDUINO_CI_ARDUINO

struct unit_test_state {
  unsigned long micros;
};

struct unit_test_state godmode {
  0, // micros
};

unsigned long millis() {
  return godmode.micros / 1000;
}

unsigned long micros() {
  return godmode.micros;
}

#endif
