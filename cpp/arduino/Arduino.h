#pragma once
/*
Mock Arduino.h library.

Where possible, variable names from the Arduino library are used to avoid conflicts

*/



#include "AvrMath.h"

struct unit_test_state {
  unsigned long micros;
};

unsigned long millis();

unsigned long micros();
