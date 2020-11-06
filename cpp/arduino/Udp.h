#pragma once

#include <Stream.h>
#include <IPAddress.h>

class UDP : public Stream {
protected:
  uint8_t *rawIPAddress(IPAddress &addr) { return addr.raw_address(); };
};
