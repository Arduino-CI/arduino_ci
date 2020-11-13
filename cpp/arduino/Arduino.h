#pragma once
/*
Mock Arduino.h library.

Where possible, variable names from the Arduino library are used to avoid conflicts

*/
// Chars and strings

#include "ArduinoDefines.h"

#include "IPAddress.h"
#include "WCharacter.h"
#include "WString.h"
#include "Print.h"
#include "Stream.h"
#include "HardwareSerial.h"

typedef bool boolean;
typedef uint8_t byte;

#include "binary.h"

// Math and Trig
#include "AvrMath.h"

#include "Godmode.h"


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
// you need interrupts? interrupt yourself
#define yield() _NOP()
#define interrupts() _NOP()
#define noInterrupts() _NOP()

// TODO: correctly establish this per-board!
#define F_CPU 1000000UL
#define clockCyclesPerMicrosecond() ( F_CPU / 1000000L )
#define clockCyclesToMicroseconds(a) ( (a) / clockCyclesPerMicrosecond() )
#define microsecondsToClockCycles(a) ( (a) * clockCyclesPerMicrosecond() )

typedef unsigned int word;

#define bit(b) (1UL << (b))




// Get the bit location within the hardware port of the given virtual pin.
// This comes from the pins_*.c file for the active board configuration.

#define analogInPinToBit(P) (P)
#define digitalPinToInterrupt(P) (P)

// uint16_t makeWord(uint16_t w);
// uint16_t makeWord(byte h, byte l);
inline unsigned int makeWord(unsigned int w) { return w; }
inline unsigned int makeWord(unsigned char h, unsigned char l) { return (h << 8) | l; }

#define word(...) makeWord(__VA_ARGS__)


