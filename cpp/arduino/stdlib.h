#pragma once

// Header file to compensate for differences between
// arduino-1.x.x/hardware/tools/avr/avr/include/stdlib.h and /usr/include/stdlib.h.

#include_next <stdlib.h>

/*
 * Arduino stdlib.h includes a prototype for itoa which is not a standard function,
 * and is not available in /usr/include/stdlib.h. Provide one here.
 * http://www.cplusplus.com/reference/cstdlib/itoa/
 * https://stackoverflow.com/questions/190229/where-is-the-itoa-function-in-linux
 */
char *itoa(int val, char *s, int radix);
