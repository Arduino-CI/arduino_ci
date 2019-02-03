#include <Arduino.h>
#include "do-something.h"
int doSomething(void) {
  millis();  // this line is only here to test that we're able to refer to the builtins
  return 4;
};

static const struct something table[] = {
	{ 1, "abc" },
	{ 2, "xyz" },
	{ 4, "123" },
};

const struct something *findSomething(int id) {
	for (unsigned int i = 0; i < 3; i++) {
		if (table[i].id == id) {
			return &table[i];
		}
	}
	return nullptr;
}

