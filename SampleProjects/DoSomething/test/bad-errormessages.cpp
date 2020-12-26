#include <ArduinoUnitTests.h>


#pragma once



unittest(check_that_assertion_error_messages_are_comprehensible)
{
  assertEqual(1 ,2);
  assertNotEqual(2, 2);
  assertComparativeEqual(1, 2);
  assertComparativeNotEqual(2, 2);
  assertLess(2, 1);
  assertMore(1, 2);
  assertLessOrEqual(2, 1);
  assertMoreOrEqual(1, 2);
  assertTrue(false);
  assertFalse(true);
  assertNull(3);
  assertNotNull(NULL);
}

unittest_main()
