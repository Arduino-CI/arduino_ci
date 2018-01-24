#include <ArduinoUnitTests.h>

unittest(pretend_equal_things_arent)
{
  int x = 3;
  int y = 3;
  assertNotEqual(x, y);
}

int main(int argc, char *argv[]) {
  return Test::run_and_report(argc, argv);
}
