#pragma once

#include <stdint.h>

class IPAddress {
private:
  union {
    uint8_t bytes[4];
    uint32_t dword;
    operator uint8_t *() const { return (uint8_t *)bytes; }
  } _address;

public:
  // Constructors
  IPAddress() : IPAddress(0, 0, 0, 0) {}
  IPAddress(uint8_t octet1, uint8_t octet2, uint8_t octet3, uint8_t octet4) {
    _address.bytes[0] = octet1;
    _address.bytes[1] = octet2;
    _address.bytes[2] = octet3;
    _address.bytes[3] = octet4;
  }
  IPAddress(uint32_t dword) { _address.dword = dword; }
  IPAddress(const uint8_t bytes[]) {
    _address.bytes[0] = bytes[0];
    _address.bytes[1] = bytes[1];
    _address.bytes[2] = bytes[2];
    _address.bytes[3] = bytes[3];
  }
  IPAddress(unsigned long dword) { _address.dword = (uint32_t)dword; }

  // Accessors
  uint32_t asWord() const { return _address.dword; }
  uint8_t *raw_address() { return _address.bytes; }

  // Comparisons
  bool operator==(const IPAddress &rhs) const {
    return _address.dword == rhs.asWord();
  }

  bool operator!=(const IPAddress &rhs) const {
    return _address.dword != rhs.asWord();
  }

  // Indexing
  uint8_t operator[](int index) const { return _address.bytes[index]; }
  uint8_t &operator[](int index) { return _address.bytes[index]; }

  // Conversions
  operator uint32_t() const { return _address.dword; };

  friend class EthernetClass;
  friend class UDP;
  friend class Client;
  friend class Server;
  friend class DhcpClass;
  friend class DNSClient;
};

const IPAddress INADDR_NONE(0, 0, 0, 0);
