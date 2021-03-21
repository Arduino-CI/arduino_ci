#pragma once
#include "ArduinoDefines.h"
#if defined(__AVR__)
#include <avr/io.h>
#endif
#include "WString.h"
#include "PinHistory.h"

// random
void randomSeed(unsigned long seed);
long random(long vmax);
long random(long vmin, long vmax);


// Time
typedef void (*DelayHandler)(unsigned long micros);
void delay(unsigned long millis);
void delayMicroseconds(unsigned long micros);
unsigned long millis();
unsigned long micros();
void addDelayHandler(DelayHandler pFunction);
void removeDelayHandler(DelayHandler pFunction);

#define MOCK_PINS_COUNT 256

#if (!defined NUM_SERIAL_PORTS)
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
#endif

// different EEPROM implementations have different macros that leak out
#if !defined(EEPROM_SIZE) && defined(E2END) && (E2END)
  // public value indicates that feature is available
  #define EEPROM_SIZE (E2END + 1)
  // local array size
  #define _EEPROM_SIZE EEPROM_SIZE
#else
  // feature is not available but we want to have the array so other code compiles
  #define _EEPROM_SIZE (0)
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

    uint8_t mmapPorts[MOCK_PINS_COUNT];

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
    uint8_t eeprom[_EEPROM_SIZE];

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

    void resetMmapPorts() {
      for (int i = 0; i < MOCK_PINS_COUNT; ++i) {
        mmapPorts[i] = 1;
      }
    }

    void resetEEPROM() {
#if defined(EEPROM_SIZE)
      for(int i = 0; i < EEPROM_SIZE; ++i) {
        eeprom[i] = 255;
      }
#endif
    }

    void reset() {
      resetClock();
      resetPins();
      resetInterrupts();
      resetPorts();
      resetSPI();
      resetMmapPorts();
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

    uint8_t* pMmapPort(uint8_t port) { return &mmapPorts[port]; }
    uint8_t mmapPortValue(uint8_t port) { return mmapPorts[port]; }

    // C++ 11, declare as public for better compiler error messages
    GodmodeState(GodmodeState const&) = delete;
    void operator=(GodmodeState const&) = delete;

  private:
    GodmodeState() {
      reset();
    }
};

// io pins
inline void pinMode(uint8_t pin, uint8_t mode) { _NOP(); }
inline void analogReference(uint8_t mode) { _NOP(); }

void digitalWrite(uint8_t, uint8_t);
int digitalRead(uint8_t);
int analogRead(uint8_t);
void analogWrite(uint8_t, int);
inline void analogReadResolution(uint8_t bits) { _NOP(); }
inline void analogWriteResolution(uint8_t bits) { _NOP(); }
void attachInterrupt(uint8_t interrupt, void ISR(void), uint8_t mode);
void detachInterrupt(uint8_t interrupt);

// TODO: issue #26 to track the commanded state here
inline void tone(uint8_t _pin, unsigned int frequency, unsigned long duration = 0) { throw "Not Yet Implemented"; }
inline void noTone(uint8_t _pin) { throw "Not Yet Implemented"; }
inline uint8_t pulseIn(uint8_t _pin, uint8_t _value, uint32_t _timeout) { throw "Not Yet Implemented"; }
inline uint8_t pulseIn(uint8_t pin, uint8_t value) { return pulseIn(pin, value, (uint32_t) 1000000); }
inline uint32_t pulseInLong(uint8_t _pin, uint8_t _value, uint32_t _timeout) { throw "Not Yet Implemented"; }
inline uint32_t pulseInLong(uint8_t pin, uint8_t value) { return pulseInLong(pin, value, (uint32_t) 1000000); }

/**
 * Shifts in a byte of data one bit at a time.
 *
 * Starts from either the most (i.e. the leftmost) or least (rightmost)
 * significant bit. For each bit, the clock pin is pulled high, the next bit is
 * read from the data line, and then the clock pin is taken low.
 *
 * @param dataPin the pin on which to input each bit
 * @param clockPin the pin to toggle to signal a read from dataPin
 * @param bitOrder which order to shift in the bits; either MSBFIRST or LSBFIRST. B=Bit, not byte
 *
 * @return The value read
 */
inline uint8_t shiftIn(uint8_t dataPin, uint8_t clockPin, bool bitOrder) {
  bool mFirst = bitOrder == MSBFIRST;
  uint8_t ret = 0x00;
  for (uint8_t i = 0, mask = (bitOrder == MSBFIRST ? 0x80 : 0x01); i < 8; ++i) {
    digitalWrite(clockPin, HIGH);
    uint8_t setBit = mFirst ? 0x80 : 0x01;
    uint8_t val = (mFirst ? (setBit >> i) : (setBit << i));
    ret = ret | (digitalRead(dataPin) ? val : 0x00);
    digitalWrite(clockPin, LOW);
  }
  return ret;
}

/**
 * Shifts out a byte of data one bit at a time.
 *
 * Starts from either the most (i.e. the leftmost) or least (rightmost)
 * significant bit. Each bit is written in turn to a data pin, after which a
 * clock pin is pulsed (taken high, then low) to indicate that the bit is
 * available.
 *
 * @param dataPin the pin on which to input each bit
 * @param clockPin the pin to toggle to signal a write from dataPin
 * @param bitOrder which order to shift in the bits; either MSBFIRST or LSBFIRST. B=Bit, not byte
 * @param value the data to shift out
 *
 * @return The value read
 */
inline void shiftOut(uint8_t dataPin, uint8_t clockPin, bool bitOrder, uint8_t value) {
  bool mFirst = bitOrder == MSBFIRST;
  uint8_t ret = 0x00;
  for (uint8_t i = 0, mask = (bitOrder == MSBFIRST ? 0x80 : 0x01); i < 8; ++i) {
    uint8_t setBit = mFirst ? 0x80 : 0x01;
    uint8_t val = (mFirst ? (setBit >> i) : (setBit << i));
    digitalWrite(dataPin, (value & val) ? HIGH : LOW);
    digitalWrite(clockPin, HIGH);
    digitalWrite(clockPin, LOW);
  }
}

// These definitions allow the following to compile (see issue #193):
// https://github.com/arduino-libraries/Ethernet/blob/master/src/utility/w5100.h:341
// we allow one byte per port which "wastes" 224 bytes, but makes the code easier
#if defined(__AVR__)
  #define digitalPinToBitMask(pin)  (1)
  #define digitalPinToPort(pin)     (pin)
  #define portInputRegister(port)   (GODMODE()->pMmapPort(port))
  #define portOutputRegister(port)  (GODMODE()->pMmapPort(port))
#else
  // we don't (yet) support other boards
#endif


GodmodeState* GODMODE();
