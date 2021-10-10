#pragma once

#include <IPAddress.h>
#include <Stream.h>

class Client : public Stream {
public:
  Client() {
    // The Stream mock defines a String buffer but never puts anyting in it!
    if (!mGodmodeDataIn) {
      mGodmodeDataIn = new String;
    }
  }
  Client(const Client &client) { // copy constructor
    if (this != &client) {       // not a self-assignment
      if (mGodmodeDataIn &&
          client.mGodmodeDataIn) { // replace what we previously had
        delete mGodmodeDataIn;     // get rid of previous value
        mGodmodeDataIn = new String(client.mGodmodeDataIn->c_str());
      }
    }
  }
  Client &operator=(const Client &client) { // copy assignment operator
    if (this != &client) {                  // not a self-assignment
      if (mGodmodeDataIn &&
          client.mGodmodeDataIn) { // replace what we previously had
        delete mGodmodeDataIn;     // get rid of previous value
        mGodmodeDataIn = new String(client.mGodmodeDataIn->c_str());
      }
    }
    return *this;
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
