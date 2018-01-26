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

#include "ArduinoDefines.h"

#include "binary.h"

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

// Arduino defines this
#define _NOP() do { 0; } while (0)

// might as well use that NO-op macro for these, while unit testing
#define yield() _NOP()
#define interrupts() _NOP()
#define noInterrupts() _NOP()

// Character stuff
#include "WCharacter.h"

// TODO: correctly establish this per-board!
#define F_CPU 1000000UL
#define clockCyclesPerMicrosecond() ( F_CPU / 1000000L )
#define clockCyclesToMicroseconds(a) ( (a) / clockCyclesPerMicrosecond() )
#define microsecondsToClockCycles(a) ( (a) * clockCyclesPerMicrosecond() )

typedef unsigned int word;

#define bit(b) (1UL << (b))

#ifndef __did_sized_types
typedef unsigned char       uint8_t;
// typedef __uint16_t      uint16_t;
// typedef __uint32_t      uint32_t;
// typedef __uint64_t      uint64_t;
#define __did_sized_types
#endif

typedef bool boolean;
typedef uint8_t byte;


// Get the bit location within the hardware port of the given virtual pin.
// This comes from the pins_*.c file for the active board configuration.

#define analogInPinToBit(P) (P)

// uint16_t makeWord(uint16_t w);
// uint16_t makeWord(byte h, byte l);
inline unsigned int makeWord(unsigned int w) { return w; }
inline unsigned int makeWord(unsigned char h, unsigned char l) { return (h << 8) | l; }

#define word(...) makeWord(__VA_ARGS__)



// Time
void delay(unsigned long millis);
void delayMicroseconds(unsigned long micros);
unsigned long millis();
unsigned long micros();

