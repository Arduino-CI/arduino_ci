#pragma once

#include <Stream.h>

// https://github.com/arduino-libraries/Ethernet/blob/master/src/utility/w5100.h:341
extern volatile uint8_t mmapPorts[MOCK_PINS_COUNT];
#define portOutputRegister(port)  (uint8_t *) (&mmapPorts[port])
#define digitalPinToPort(pin)     (pin)
#define digitalPinToBitMask(pin)  (1)

class Client : public Stream {
protected:
  uint8_t* rawIPAddress(IPAddress& addr) { return addr.raw_address(); };
};
