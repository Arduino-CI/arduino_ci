#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(binary)
{
  assertEqual(1, B1);
  assertEqual(10, B1010);
  assertEqual(100, B1100100);
}

unittest_main()
