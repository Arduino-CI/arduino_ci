#pragma once

// fibbonacci clock
unsigned long lastFakeMicros = 1;
unsigned long fakeMicros = 0;

void resetFibClock() {
  lastFakeMicros = 1;
  fakeMicros = 0;
}

unsigned long fibMicros() {
  unsigned long ret = lastFakeMicros + fakeMicros;
  lastFakeMicros = fakeMicros;
  fakeMicros = ret;
  return ret;
}
