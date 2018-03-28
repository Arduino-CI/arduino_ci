#pragma once

//#include <inttypes.h>
#include "Stream.h"

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

class HardwareSerial : public Stream, public ObservableDataStream
{
  protected:
    String* mGodmodeDataOut;

  public:
    HardwareSerial(String* dataIn, String* dataOut, unsigned long* delay): Stream(), ObservableDataStream() {
      mGodmodeDataIn      = dataIn;
      mGodmodeDataOut     = dataOut;
      mGodmodeMicrosDelay = delay;
    }
    void begin(unsigned long baud) { begin(baud, SERIAL_8N1); }
    void begin(unsigned long baud, uint8_t config) {
      *mGodmodeMicrosDelay = 1000000 / baud;
    }
    void end() {}

    // virtual int available(void);
    // virtual int peek(void);
    // virtual int read(void);
    // virtual int availableForWrite(void);
    // virtual void flush(void);
    virtual size_t write(uint8_t aChar) {
      mGodmodeDataOut->append(String((char)aChar));
      advertiseByte((unsigned char)aChar);
      return 1;
    }

    inline size_t write(unsigned long n) { return write((uint8_t)n); }
    inline size_t write(long n) { return write((uint8_t)n); }
    inline size_t write(unsigned int n) { return write((uint8_t)n); }
    inline size_t write(int n) { return write((uint8_t)n); }
    using Print::write; // pull in write(str) and write(buf, size) from Print
    operator bool() { return true; }

};

#if defined(UBRRH) || defined(UBRR0H)
  extern HardwareSerial Serial;
  #define HAVE_HWSERIAL0
#endif
#if defined(UBRR1H)
  extern HardwareSerial Serial1;
  #define HAVE_HWSERIAL1
#endif
#if defined(UBRR2H)
  extern HardwareSerial Serial2;
  #define HAVE_HWSERIAL2
#endif
#if defined(UBRR3H)
  extern HardwareSerial Serial3;
  #define HAVE_HWSERIAL3
#endif

