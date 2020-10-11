#pragma once
#include "ArduinoDefines.h"
#include <avr/io.h>
#include "WString.h"
#include "PinHistory.h"
#include "EEPROM.h"

// random
void randomSeed(unsigned long seed);
long random(long vmax);
long random(long vmin, long vmax);


// Time
void delay(unsigned long millis);
void delayMicroseconds(unsigned long micros);
unsigned long millis();
unsigned long micros();

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
  private:
    struct PortDef {
      String dataIn;
      String dataOut;
      unsigned long readDelayMicros;
    };

    struct InterruptDef {
      bool attached;
      uint8_t mode;
    };

    static GodmodeState* instance;

  public:
    unsigned long micros;
    unsigned long seed;
    // not going to put pinmode here unless its really needed. can't think of why it would be
    PinHistory<bool> digitalPin[MOCK_PINS_COUNT];
    PinHistory<int> analogPin[MOCK_PINS_COUNT];
    struct PortDef serialPort[NUM_SERIAL_PORTS];
    struct InterruptDef interrupt[MOCK_PINS_COUNT]; // not sure how to get actual number
    struct PortDef spi;

    void resetPins() {
      for (int i = 0; i < MOCK_PINS_COUNT; ++i) {
        digitalPin[i].reset(LOW);
        analogPin[i].reset(0);
      }
    }

    void resetClock() {
      micros = 0;
    }

    void resetInterrupts() {
      for (int i = 0; i < MOCK_PINS_COUNT; ++i) {
        interrupt[i].attached = false;
      }
    }

    void resetPorts() {
      for (int i = 0; i < serialPorts(); ++i)
      {
        serialPort[i].dataIn = "";
        serialPort[i].dataOut = "";
        serialPort[i].readDelayMicros = 0;
      }
    }

    void resetSPI() {
      spi.dataIn = "";
      spi.dataOut = "";
      spi.readDelayMicros = 0;
    }

    void resetEEPROM() {
      for(int i = 0; i < EEPROM.length(); ++i){
        EEPROM.update(i, 255);
      }
    }

    void reset() {
      resetClock();
      resetPins();
      resetInterrupts();
      resetPorts();
      resetSPI();
      resetEEPROM();
      seed = 1;
    }

    int serialPorts() {
      return NUM_SERIAL_PORTS;
    }

    // Using this for anything other than unit testing arduino_ci itself
    // is unsupported at the moment
    void overrideClockTruth(unsigned long (*getMicros)(void)) {
    }

    // singleton pattern
    static GodmodeState* getInstance();

    static unsigned long getMicros() {
      return instance->micros;
    }

    // C++ 11, declare as public for better compiler error messages
    GodmodeState(GodmodeState const&) = delete;
    void operator=(GodmodeState const&) = delete;

  private:
    GodmodeState() {
      reset();
    }
};

// io pins
#define pinMode(...) _NOP()
#define analogReference(...) _NOP()

void digitalWrite(uint8_t, uint8_t);
int digitalRead(uint8_t);
int analogRead(uint8_t);
void analogWrite(uint8_t, int);
#define analogReadResolution(...) _NOP()
#define analogWriteResolution(...) _NOP()
void attachInterrupt(uint8_t interrupt, void ISR(void), uint8_t mode);
void detachInterrupt(uint8_t interrupt);

// TODO: issue #26 to track the commanded state here
inline void tone(uint8_t _pin, unsigned int frequency, unsigned long duration = 0) {}
inline void noTone(uint8_t _pin) {}


GodmodeState* GODMODE();
