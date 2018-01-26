#include "Arduino.h"

GodmodeState godmode = GodmodeState();

GodmodeState* GODMODE() {
  return &godmode;
}

unsigned long millis() {
  return godmode.micros / 1000;
}

unsigned long micros() {
  return godmode.micros;
}

void delay(unsigned long millis) {
  godmode.micros += millis * 1000;
}

void delayMicroseconds(unsigned long micros) {
  godmode.micros += micros;
}
