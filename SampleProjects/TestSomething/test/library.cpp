#include <ArduinoUnitTests.h>
#include "../src/test-something.h"

unittest(library_tests_something)
{
  assertEqual(4, testSomething());
}

unittest(library_returns_nullptr)
{
  assertEqual(nullptr, aNullPointer());
}

unittest_main()
