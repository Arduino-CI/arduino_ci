#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(abs)
{
  assertEqual(1, abs(1));
  assertEqual(1, abs(-1));
  assertEqual(1.0, abs(1.0));
  assertEqual(1.0, abs(-1.0));
}

unittest(constrain)
{
  assertEqual(3, constrain(1, 3, 5));
  assertEqual(5, constrain(9, 3, 5));
  assertEqual(2.0, constrain(1, 2.0, 5));
  assertEqual(6.0, constrain(1.3, 6.0, 9));
}

unittest(map)
{
  assertEqual(30, map(3, 0, 10, 0, 100));
  assertEqual(30, map(20, 0, 50, 50, 0));
  assertEqual(-4, map(26, 0, 50, 100, -100));
}

unittest(max)
{
  assertEqual(4, max(3, 4));
  assertEqual(5, max(3.0, 5));
  assertEqual(6.0, max(-4, 6.0));
  assertEqual(7.0, max(5.0, 7.0));
}

unittest(min)
{
  assertEqual(3, min(3, 4));
  assertEqual(3.0, min(3.0, 5));
  assertEqual(-4, min(-4, 6.0));
  assertEqual(5.0, min(5.0, 7.0));
}

unittest(pow)
{
  assertEqual(4.0, pow(2, 2));
  assertEqual(4.0, pow(2.0, 2.0));
  assertEqual(0.125, pow(2, -3));
  assertLess(1.41420, pow(2, 0.5));
  assertMore(1.41422, pow(2, 0.5));
}

unittest(sq)
{
  assertEqual(9, sq(3));
  assertEqual(9.0, sq(3.0));
  assertEqual(9, sq(-3));
  assertEqual(9.0, sq(-3.0));
  assertEqual(0.25, sq(0.5));
  assertEqual(0.25, sq(-0.5));
}

unittest(sqrt)
{
  assertEqual(3, sqrt(9));
  assertEqual(3.0, sqrt(9.0));
}


unittest_main()
