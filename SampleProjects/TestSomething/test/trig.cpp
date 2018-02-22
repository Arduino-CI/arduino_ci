#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(floor)
{
  assertEqual(1, floor(1.9));
  assertEqual(1, floor(1));
  assertEqual(1, floor(1.0));
  assertEqual(1, floor(1.9999999));
}

unittest(cos)
{
  assertEqual(1.0, cos(0));
  assertLess(-0.01, cos(3.141 / 2));
  assertMore(0.01, cos(3.141 / 2));
  assertMore(-0.99, cos(PI));
  assertLess(-1.01, cos(PI));
  assertLess(-0.01, cos(radians(90)));
  assertMore(0.01, cos(radians(90)));
}

unittest_main()
