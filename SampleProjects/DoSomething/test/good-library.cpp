#include <ArduinoUnitTests.h>
#include "../do-something.h"

unittest(library_does_something)
{
  assertEqual(4, doSomething());
}

unittest_main()
