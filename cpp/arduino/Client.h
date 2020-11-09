#pragma once

#include <Stream.h>

class Client : public Stream {
public:
  Client() {
    // The Stream mock defines a String buffer but never puts anyting in it!
    if (!mGodmodeDataIn) {
      mGodmodeDataIn = new String;
    }
  }
  ~Client() {
    if (mGodmodeDataIn) {
      delete mGodmodeDataIn;
      mGodmodeDataIn = nullptr;
    }
  }
  virtual size_t write(uint8_t value) {
    mGodmodeDataIn->concat(value);
    return 1;
  }

protected:
  uint8_t *rawIPAddress(IPAddress &addr) { return addr.raw_address(); }
};
