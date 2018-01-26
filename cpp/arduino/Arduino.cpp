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

void digitalWrite(uint8_t pin, uint8_t val) {
  godmode.digitalPin[pin] = val;
}

int digitalRead(uint8_t pin) {
  return godmode.digitalPin[pin];
}

int analogRead(uint8_t pin) {
  return godmode.analogPin[pin];
}

void analogWrite(uint8_t pin, int val) {
  godmode.analogPin[pin] = val;
}
