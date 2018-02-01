#pragma once
#include "ArduinoDefines.h"
#include "WString.h"

#define MOCK_PINS_COUNT 256

#if defined(UBRR3H)
  #define NUM_SERIAL_PORTS 4
#elif defined(UBRR2H)
  #define NUM_SERIAL_PORTS 3
#elif defined(UBRR1H)
  #define NUM_SERIAL_PORTS 2
#elif defined(UBRRH) || defined(UBRR0H)
  #define NUM_SERIAL_PORTS 1
#else
  #define NUM_SERIAL_PORTS 0
#endif


class GodmodeState {
  struct PortDef {
    String dataIn;
    String dataOut;
    unsigned long readDelayMicros;
  };

  public:
    unsigned long micros;
    unsigned long seed;
    // not going to put pinmode here unless its really needed. can't think of why it would be
    bool digitalPin[MOCK_PINS_COUNT];
    int analogPin[MOCK_PINS_COUNT];
    struct PortDef serialPort[NUM_SERIAL_PORTS];

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
      for (int i = 0; i < NUM_SERIAL_PORTS; ++i) {
        serialPort[i] = {"", "", 0};
      }
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

