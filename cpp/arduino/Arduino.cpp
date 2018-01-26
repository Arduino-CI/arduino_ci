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


void randomSeed(unsigned long seed)
{
  godmode.seed = seed;
}

long random(long vmax)
{
  godmode.seed += 4294967291;  // it's a prime that fits in 32 bits
  return godmode.seed % vmax;
}

long random(long vmin, long vmax)
{
  return vmin < vmax ? (random(vmax - vmin) + vmin) : vmin;
}
