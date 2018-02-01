#include "Arduino.h"
#include "Godmode.h"


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
