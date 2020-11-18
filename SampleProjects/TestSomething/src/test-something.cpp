#include "test-something.h"
int testSomething(void) {
  millis();  // this line is only here to test that we're able to refer to the builtins
  return 4;
};

int* aNullPointer(void) {
  int* ret = nullptr;
  return ret;
}
