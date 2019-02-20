#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include "fibonacciClock.h"

unittest(my_fib_clock)
{
  resetFibClock();
  assertEqual(1, fibMicros());
  assertEqual(1, fibMicros());
  assertEqual(2, fibMicros());
  assertEqual(3, fibMicros());
  assertEqual(5, fibMicros());
  assertEqual(8, fibMicros());
  assertEqual(13, fibMicros());
  assertEqual(21, fibMicros());

  // and again
  resetFibClock();
  assertEqual(1, fibMicros());
  assertEqual(1, fibMicros());
  assertEqual(2, fibMicros());
}


unittest_main()
