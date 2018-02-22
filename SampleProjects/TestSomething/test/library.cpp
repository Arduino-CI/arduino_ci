#include <ArduinoUnitTests.h>
#include "../test-something.h"

unittest(library_tests_something)
{
  assertEqual(4, testSomething());
}

unittest_main()
