#pragma once

#include <cassert>
#include <inttypes.h>
#include <Godmode.h>

// Does the current board have EEPROM?
#ifndef EEPROM_SIZE
  // In lieu of an "EEPROM.h not found" error for unsupported boards
  #error "EEPROM library not available for your board"
#endif

class EEPROMClass {
private:
  GodmodeState* state;
public:
  // constructor
  EEPROMClass() {
    state = GODMODE();
  }
  // array subscript operator
  uint8_t &operator[](const int index) {
    assert(index < EEPROM_SIZE);
    return state->eeprom[index];
  }

  uint8_t read(const int index) {
    assert(index < EEPROM_SIZE);
    return state->eeprom[index];
  }

  void write(const int index, const uint8_t value) {
    assert(index < EEPROM_SIZE);
    state->eeprom[index] = value;
  }

  void update(const int index, const uint8_t value) {
    assert(index < EEPROM_SIZE);
    state->eeprom[index] = value;
  }

  uint16_t length() { return EEPROM_SIZE; }

  // read any object
  template <typename T> T &get(const int index, T &object) {
    uint8_t *ptr = (uint8_t *)&object;
    for (int i = 0; i < sizeof(T); ++i) {
      *ptr++ = read(index + i);
    }
    return object;
  }

  // write any object
  template <typename T> const T &put(const int index, T &object) {
    const uint8_t *ptr = (const uint8_t *)&object;
    for (int i = 0; i < sizeof(T); ++i) {
      write(index + i, *ptr++);
    }
    return object;
  }
};

// global available in Godmode.cpp
extern EEPROMClass EEPROM;
