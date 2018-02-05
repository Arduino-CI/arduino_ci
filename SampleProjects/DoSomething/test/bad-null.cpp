#include <ArduinoUnitTests.h>

unittest(pretend_equal_things_arent)
{
  int x = 3;
  int y = 3;
  assertNotEqual(x, y);
}

unittest_main()
