#include <ArduinoUnitTests.h>

#include "do-something.h"

unittest(find_something_that_exists)
{
  const struct something *result;
  result = findSomething(1);
  assertNotNull(result);
  assertEqual("abc", result->text);
}

unittest(find_something_that_does_not_exists)
{
  const struct something *result;
  result = findSomething(1000);
  assertNull(result);
}

unittest_main()

