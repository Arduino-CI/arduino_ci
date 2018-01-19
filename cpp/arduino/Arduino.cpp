#include "Arduino.h"

struct unit_test_state godmode = {
  0, // micros
};

unsigned long millis() {
  return godmode.micros / 1000;
}

unsigned long micros() {
  return godmode.micros;
}
