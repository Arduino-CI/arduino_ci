#include <ArduinoUnitTests.h>
#include "../do-something.h"

unittest(library_does_something)
{
  assertEqual(4, doSomething());
}

int main(int argc, char *argv[]) {
  return Test::run_and_report(argc, argv);
}
