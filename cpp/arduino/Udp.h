#pragma once

#include <Stream.h>
#include <IPAddress.h>

class UDP : public Stream {
protected:
  uint8_t *rawIPAddress(IPAddress &addr) { return addr.raw_address(); };

public:
  UDP() {
    // The Stream mock defines a String buffer but never puts anyting in it!
    if (!mGodmodeDataIn) {
      mGodmodeDataIn = new String;
    }
  }
  virtual size_t write(uint8_t value) {
    mGodmodeDataIn->concat(value);
    return 1;
  }
};
