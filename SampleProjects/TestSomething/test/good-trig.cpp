#include <ArduinoUnitTests.h>
#include "../test-something.h"

unittest(floor)
{
  assertEqual(1, floor(1.9));
  assertEqual(1, floor(1));
  assertEqual(1, floor(1.0));
  assertEqual(1, floor(1.9999999));
}

unittest_main()
