#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(millis_micros_and_delay)
{
  GodmodeState* state = GODMODE();
  state->reset();
  assertEqual(0, millis());
  assertEqual(0, micros());
  delay(3);
  assertEqual(3, millis());
  assertEqual(3000, micros());
  delayMicroseconds(11000);
  assertEqual(14, millis());
  assertEqual(14000, micros());
}

unittest(random)
{
  randomSeed(1);
  unsigned long x;
  x = random(4294967293);
  assertEqual(4294967292, x);
  x = random(50, 100);
  assertEqual(83, x);
  x = random(100);
  assertEqual(74, x);
}

unittest_main()
