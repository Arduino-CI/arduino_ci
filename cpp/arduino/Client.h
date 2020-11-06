#pragma once

#include <Stream.h>

class Client : public Stream {
protected:
  uint8_t* rawIPAddress(IPAddress& addr) { return addr.raw_address(); };
};
