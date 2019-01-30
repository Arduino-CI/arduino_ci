#include <test-something.h>
// if it seems bare, that's because it's only meant to
// demonstrate compilation -- that references work
void setup() {
  int *p = nullptr;
}

void loop() {
  testSomething();
}
