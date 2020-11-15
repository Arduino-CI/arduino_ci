#pragma once

#include <IPAddress.h>
#include <Stream.h>

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
  ~UDP() {
    if (mGodmodeDataIn) {
      delete mGodmodeDataIn;
      mGodmodeDataIn = nullptr;
    }
  }
  virtual size_t write(uint8_t value) {
    mGodmodeDataIn->concat(value);
    return 1;
  }
};
