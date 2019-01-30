#include <ArduinoUnitTests.h>

unittest(equality_as_vars)
{
  int x = 3;
  int y = 3;
  int z = 3;
  assertEqual(x, y);
  assertEqual(x, z);
}

unittest(equality_as_values)
{
  assertEqual(1, 1);
  assertEqual(4, 4);
}

unittest(nothing)
{
}

unittest(nullpointer)
{
  int* myPointer = NULL;
  int **notNullPointer = &myPointer;

  assertNull(myPointer);
  assertNull(nullptr);
  assertEqual(myPointer, nullptr);
  assertNotEqual(nullptr, notNullPointer);
  assertNotNull(notNullPointer);
}

unittest(nullpointer_equal)
{
  int* myPointer = NULL;
  int **notNullPointer = &myPointer;
  assertEqual(nullptr, myPointer);
  assertNotEqual(nullptr, notNullPointer);

  assertLessOrEqual(nullptr, myPointer);
  assertMoreOrEqual(myPointer, nullptr);
  assertLessOrEqual(nullptr, notNullPointer);
  assertMoreOrEqual(notNullPointer, nullptr);
  assertLessOrEqual(myPointer, nullptr);
  assertMoreOrEqual(notNullPointer, nullptr);
  assertLess(nullptr, notNullPointer);
  assertMore(notNullPointer, nullptr);
}

unittest_main()
