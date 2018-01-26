#pragma once
/*
Mock Arduino.h library.

Where possible, variable names from the Arduino library are used to avoid conflicts

*/

class GodmodeState {
  public:
    unsigned long micros;

    void resetClock() {
      micros = 0;
    }

    void reset() {
      resetClock();
    }

    GodmodeState() {
      reset();
    }

};

GodmodeState* GODMODE();


// Math and Trig
#include "AvrMath.h"

// Bits and Bytes
#define bit(b) (1UL << (b))
#define bitClear(value, bit) ((value) &= ~(1UL << (bit)))
#define bitRead(value, bit) (((value) >> (bit)) & 0x01)
#define bitSet(value, bit) ((value) |= (1UL << (bit)))
#define bitWrite(value, bit, bitvalue) (bitvalue ? bitSet(value, bit) : bitClear(value, bit))
#define highByte(w) ((uint8_t) ((w) >> 8))
#define lowByte(w) ((uint8_t) ((w) & 0xff))



// Time
void delay(unsigned long millis);
void delayMicroseconds(unsigned long micros);
unsigned long millis();
unsigned long micros();

