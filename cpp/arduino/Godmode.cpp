#include "Godmode.h"
#include "HardwareSerial.h"
#include "SPI.h"
#include "Wire.h"

GodmodeState* GODMODE() {
  return GodmodeState::getInstance();
}

GodmodeState* GodmodeState::instance = nullptr;

GodmodeState* GodmodeState::getInstance()
{
    if (instance == nullptr)
    {
        instance = new GodmodeState();
        for (int i = 0; i < MOCK_PINS_COUNT; ++i) {
          instance->digitalPin[i].setMicrosRetriever(&GodmodeState::getMicros);
          instance->analogPin[i].setMicrosRetriever(&GodmodeState::getMicros);
        }
    }

    return instance;
}

unsigned long millis() {
  return GODMODE()->micros / 1000;
}

unsigned long micros() {
  return GODMODE()->micros;
}

void delay(unsigned long millis) {
  GODMODE()->micros += millis * 1000;
}

void delayMicroseconds(unsigned long micros) {
  GODMODE()->micros += micros;
}

void randomSeed(unsigned long seed)
{
  GODMODE()->seed = seed;
}

long random(long vmax)
{
  GodmodeState* godmode = GODMODE();
  godmode->seed += 4294967291;  // it's a prime that fits in 32 bits
  godmode->seed = godmode->seed % 4294967296; // explicitly wrap in case we're on a 64-bit impl
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
  return godmode->digitalPin[pin].retrieve();
}

void analogWrite(unsigned char pin, int val) {
  GodmodeState* godmode = GODMODE();
  godmode->analogPin[pin] = val;
}

int analogRead(unsigned char pin) {
  GodmodeState* godmode = GODMODE();
  return godmode->analogPin[pin].retrieve();
}

void attachInterrupt(uint8_t interrupt, void ISR(void), uint8_t mode) {
  GodmodeState* godmode = GODMODE();
  godmode->interrupt[interrupt].attached = true;
  godmode->interrupt[interrupt].mode = mode;
}

void detachInterrupt(uint8_t interrupt) {
  GodmodeState* godmode = GODMODE();
  godmode->interrupt[interrupt].attached = false;
}

// Serial ports
#if defined(HAVE_HWSERIAL0)
  HardwareSerial Serial(&GODMODE()->serialPort[0].dataIn, &GODMODE()->serialPort[0].dataOut, &GODMODE()->serialPort[0].readDelayMicros);
#endif
#if defined(HAVE_HWSERIAL1)
  HardwareSerial Serial1(&GODMODE()->serialPort[1].dataIn, &GODMODE()->serialPort[1].dataOut, &GODMODE()->serialPort[1].readDelayMicros);
#endif
#if defined(HAVE_HWSERIAL2)
  HardwareSerial Serial2(&GODMODE()->serialPort[2].dataIn, &GODMODE()->serialPort[2].dataOut, &GODMODE()->serialPort[2].readDelayMicros);
#endif
#if defined(HAVE_HWSERIAL3)
  HardwareSerial Serial3(&GODMODE()->serialPort[3].dataIn, &GODMODE()->serialPort[3].dataOut, &GODMODE()->serialPort[3].readDelayMicros);
#endif

template <typename T>
inline std::ostream& operator << ( std::ostream& out, const PinHistory<T>& ph ) {
  out << ph;
  return out;
}

// defined in SPI.h
SPIClass SPI = SPIClass(&GODMODE()->spi.dataIn, &GODMODE()->spi.dataOut);

// defined in Wire.h
TwoWire Wire = TwoWire();

#if defined(EEPROM_SIZE)
  #include <EEPROM.h>
  EEPROMClass EEPROM;
#endif

volatile uint8_t __ARDUINO_CI_SFR_MOCK[1024];
