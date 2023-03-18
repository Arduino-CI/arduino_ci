#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <util/atomic.h>


unittest(atomic)
{
  // The macros don't do anything on the host platform, just make sure
  // they compile without error.

  int a = 1;
  int b = 2;

  ATOMIC_BLOCK(ATOMIC_RESTORESTATE) {
    a += b;
    b++;
  }

  ATOMIC_BLOCK(ATOMIC_FORCEON) {
    a += b;
    b++;
  }

  NONATOMIC_BLOCK(NONATOMIC_RESTORESTATE) {
    a += b;
    b++;
  }

  NONATOMIC_BLOCK(NONATOMIC_FORCEOFF) {
    a += b;
    b++;
  }

  assertEqual(a, 15);
  assertEqual(b, 6);
}


unittest_main()
