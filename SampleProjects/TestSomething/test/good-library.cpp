#include <ArduinoUnitTests.h>
#include "../test-something.h"

unittest(library_tests_something)
{
  assertEqual(4, testSomething());
}

int main(int argc, char *argv[]) {
  return Test::run_and_report(argc, argv);
}
