#include <ArduinoUnitTests.h>


#pragma once



unittest(check_that_assertion_error_messages_are_comprehensible)
{
  assertEqual(1, 2);
  assertNotEqual(2, 2);
  assertComparativeEquivalent(1, 2);
  assertComparativeNotEquivalent(2, 2);
  assertLess(2, 1);
  assertMore(1, 2);
  assertLessOrEqual(2, 1);
  assertMoreOrEqual(1, 2);
  assertTrue(false);
  assertFalse(true);
  assertNull(3);
  assertNotNull(NULL);

  assertEqualFloat(1.2, 1.0, 0.01);
  assertNotEqualFloat(1.0, 1.02, 0.1);
  assertInfinity(42);
  assertNotInfinity(INFINITY);
  assertNAN(42);
  assertNotNAN(0.0/0.0);
}

unittest_main()
