#pragma once
#include "ArduinoDefines.h"

#define MOCK_PINS_COUNT 256

class GodmodeState {
  public:
    unsigned long micros;
    unsigned long seed;
    // not going to put pinmode here unless its really needed. can't think of why it would be
    bool digitalPin[MOCK_PINS_COUNT];
    int analogPin[MOCK_PINS_COUNT];

    void resetPins() {
      for (int i = 0; i < MOCK_PINS_COUNT; ++i) {
        digitalPin[i] = LOW;
        analogPin[i] = 0;
      }
    }

    void resetClock() {
      micros = 0;
    }

    void reset() {
      resetClock();
      resetPins();
      seed = 1;
    }

    GodmodeState() {
      reset();
    }

};

GodmodeState* GODMODE();

// random
void randomSeed(unsigned long seed);
long random(long vmax);
long random(long vmin, long vmax);


// Time
void delay(unsigned long millis);
void delayMicroseconds(unsigned long micros);
unsigned long millis();
unsigned long micros();

