#include "Arduino.h"
#include "Godmode.h"

unsigned long millis() {
  GodmodeState* godmode = GODMODE();
  return godmode->micros / 1000;
}

unsigned long micros() {
  GodmodeState* godmode = GODMODE();
  return godmode->micros;
}

void delay(unsigned long millis) {
  GodmodeState* godmode = GODMODE();
  godmode->micros += millis * 1000;
}

void delayMicroseconds(unsigned long micros) {
  GodmodeState* godmode = GODMODE();
  godmode->micros += micros;
}


void randomSeed(unsigned long seed)
{
  GodmodeState* godmode = GODMODE();
  godmode->seed = seed;
}

long random(long vmax)
{
  GodmodeState* godmode = GODMODE();
  godmode->seed += 4294967291;  // it's a prime that fits in 32 bits
  return godmode->seed % vmax;
}

long random(long vmin, long vmax)
{
  return vmin < vmax ? (random(vmax - vmin) + vmin) : vmin;
}

void digitalWrite(unsigned char pin, unsigned char val) {
  GodmodeState* godmode = GODMODE();
  godmode->digitalPin[pin] = val;
}

int digitalRead(unsigned char pin) {
  GodmodeState* godmode = GODMODE();
  return godmode->digitalPin[pin];
}

int analogRead(unsigned char pin) {
  GodmodeState* godmode = GODMODE();
  return godmode->analogPin[pin];
}

void analogWrite(unsigned char pin, int val) {
  GodmodeState* godmode = GODMODE();
  godmode->analogPin[pin] = val;
}
