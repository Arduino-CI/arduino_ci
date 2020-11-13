#pragma once

//#include <inttypes.h>
#include "ci/StreamTape.h"

// definitions neeeded for Serial.begin's config arg
#define SERIAL_5N1 0x00
#define SERIAL_6N1 0x02
#define SERIAL_7N1 0x04
#define SERIAL_8N1 0x06
#define SERIAL_5N2 0x08
#define SERIAL_6N2 0x0A
#define SERIAL_7N2 0x0C
#define SERIAL_8N2 0x0E
#define SERIAL_5E1 0x20
#define SERIAL_6E1 0x22
#define SERIAL_7E1 0x24
#define SERIAL_8E1 0x26
#define SERIAL_5E2 0x28
#define SERIAL_6E2 0x2A
#define SERIAL_7E2 0x2C
#define SERIAL_8E2 0x2E
#define SERIAL_5O1 0x30
#define SERIAL_6O1 0x32
#define SERIAL_7O1 0x34
#define SERIAL_8O1 0x36
#define SERIAL_5O2 0x38
#define SERIAL_6O2 0x3A
#define SERIAL_7O2 0x3C
#define SERIAL_8O2 0x3E

class HardwareSerial : public StreamTape
{
  public:
    HardwareSerial(String* dataIn, String* dataOut, unsigned long* delay): StreamTape(dataIn, dataOut, delay) {}

    void begin(unsigned long baud) { begin(baud, SERIAL_8N1); }
    void begin(unsigned long baud, uint8_t config) {
      *mGodmodeMicrosDelay = 1000000 / baud;
    }
    void end() {}

    // support "if (Serial1) {}" sorts of things
    operator bool() { return true; }
};

#if NUM_SERIAL_PORTS >= 1
  extern HardwareSerial Serial;
  #define HAVE_HWSERIAL0
#endif
#if NUM_SERIAL_PORTS >= 2
  extern HardwareSerial Serial1;
  #define HAVE_HWSERIAL1
#endif
#if NUM_SERIAL_PORTS >= 3
  extern HardwareSerial Serial2;
  #define HAVE_HWSERIAL2
#endif
#if NUM_SERIAL_PORTS >= 4
  extern HardwareSerial Serial3;
  #define HAVE_HWSERIAL3
#endif

