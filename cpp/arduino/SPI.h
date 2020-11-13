#pragma once

#include "Stream.h"

// defines from original file
#define _SPI_H_INCLUDED
#define SPI_HAS_TRANSACTION 1
#define SPI_HAS_NOTUSINGINTERRUPT 1
#define SPI_ATOMIC_VERSION 1
#define SPI_CLOCK_DIV4 0x00
#define SPI_CLOCK_DIV16 0x01
#define SPI_CLOCK_DIV64 0x02
#define SPI_CLOCK_DIV128 0x03
#define SPI_CLOCK_DIV2 0x04
#define SPI_CLOCK_DIV8 0x05
#define SPI_CLOCK_DIV32 0x06
#define SPI_MODE0 0x00
#define SPI_MODE1 0x04
#define SPI_MODE2 0x08
#define SPI_MODE3 0x0C
#define SPI_MODE_MASK 0x0C
#define SPI_CLOCK_MASK 0x03
#define SPI_2XCLOCK_MASK 0x01

#ifndef LSBFIRST
#define LSBFIRST 0
#endif
#ifndef MSBFIRST
#define MSBFIRST 1
#endif

#if defined(EIMSK)
  #define SPI_AVR_EIMSK  EIMSK
#elif defined(GICR)
  #define SPI_AVR_EIMSK  GICR
#elif defined(GIMSK)
  #define SPI_AVR_EIMSK  GIMSK
#endif


class SPISettings {
public:
  uint8_t bitOrder;

  SPISettings(uint32_t clock, uint8_t bitOrder = MSBFIRST, uint8_t dataMode = SPI_MODE0) {
    this->bitOrder = bitOrder;
  };
  SPISettings(){};
};


class SPIClass: public ObservableDataStream {
public:

  SPIClass(String* dataIn, String* dataOut) {
    this->dataIn = dataIn;
    this->dataOut = dataOut;
  }

  // Initialize the SPI library
  void begin() { isStarted = true; }

  // Disable the SPI bus
  void end() { isStarted = false; }

  // this has no tangible effect in a mocked Arduino
  void usingInterrupt(uint8_t interruptNumber){}
  void notUsingInterrupt(uint8_t interruptNumber){}

  // Before using SPI.transfer() or asserting chip select pins,
  // this function is used to gain exclusive access to the SPI bus
  // and configure the correct settings.
  void beginTransaction(SPISettings settings)
  {
    this->bitOrder = settings.bitOrder;
    #ifdef SPI_TRANSACTION_MISMATCH_LED
    if (inTransactionFlag) {
      pinMode(SPI_TRANSACTION_MISMATCH_LED, OUTPUT);
      digitalWrite(SPI_TRANSACTION_MISMATCH_LED, HIGH);
    }
    inTransactionFlag = 1;
    #endif
  }

  // Write to the SPI bus (MOSI pin) and also receive (MISO pin)
  uint8_t transfer(uint8_t data) {
    //FIXME!
    // push memory->bus
    dataOut->append(String((char)data));
    advertiseByte((char)data);

    // pop bus->memory data from its queue and return it
    if (dataIn->empty()) return 0;
    char ret = (*dataIn)[0];
    *dataIn = dataIn->substr(1, dataIn->length());
    return ret;
  }

  uint16_t transfer16(uint16_t data) {
    union { uint16_t val; struct { uint8_t lsb; uint8_t msb; }; } in, out;
    in.val = data;
    if (bitOrder == MSBFIRST) {
      out.msb = transfer(in.msb);
      out.lsb =  transfer(in.lsb);
    }
    else
    {
      out.lsb =  transfer(in.lsb);
      out.msb = transfer(in.msb);
    }
    return out.val;
  }

  void transfer(void *buf, size_t count) {
    // TODO: this logic is rewritten from the original,
    // I'm not sure what role the SPDR register (which I removed) plays

    uint8_t *p = (uint8_t *)buf;
    for (int i = 0; i < count; ++i) {
      *(p + i) = transfer(*(p + i));
    }
  }

  // After performing a group of transfers and releasing the chip select
  // signal, this function allows others to access the SPI bus
  void endTransaction(void) {
    #ifdef SPI_TRANSACTION_MISMATCH_LED
    if (!inTransactionFlag) {
      pinMode(SPI_TRANSACTION_MISMATCH_LED, OUTPUT);
      digitalWrite(SPI_TRANSACTION_MISMATCH_LED, HIGH);
    }
    inTransactionFlag = 0;
    #endif
  }

  // deprecated functions, skip 'em
  void setBitOrder(uint8_t bitOrder){}
  void setDataMode(uint8_t dataMode){}
  void setClockDivider(uint8_t clockDiv){}
  void attachInterrupt(){}
  void detachInterrupt(){}

private:
  uint8_t initialized;   // initialized in Godmode.cpp
  uint8_t interruptMode; // 0=none, 1=mask, 2=global
  uint8_t interruptMask; // which interrupts to mask
  uint8_t interruptSave; // temp storage, to restore state
  #ifdef SPI_TRANSACTION_MISMATCH_LED
  uint8_t inTransactionFlag;
  #endif

  bool isStarted = false;
  uint8_t bitOrder;
  String* dataIn;
  String* dataOut;
};

extern SPIClass SPI;
