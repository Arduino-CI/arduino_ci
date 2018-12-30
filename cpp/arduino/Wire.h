
#pragma once

#include <inttypes.h>
#include "Stream.h"

class TwoWire : public ObservableDataStream
{
public:
  TwoWire() {
  }

  // https://www.arduino.cc/en/Reference/WireBegin
  // Initiate the Wire library and join the I2C bus as a master or slave. This should normally be called only once.
  void begin() {
    isMaster = true;
  }
  void begin(int address) {
    i2cAddress = address;
    isMaster = false;
  }
  void begin(uint8_t address) {
    begin((int)address);
  }
  void end() {
    // TODO: implement
  }

  // https://www.arduino.cc/en/Reference/WireSetClock
  // This function modifies the clock frequency for I2C communication. I2C slave devices have no minimum working
  // clock frequency, however 100KHz is usually the baseline.
  void setClock(uint32_t) {
    // TODO: implement?
  }

  // https://www.arduino.cc/en/Reference/WireBeginTransmission
  // Begin a transmission to the I2C slave device with the given address. Subsequently, queue bytes for
  // transmission with the write() function and transmit them by calling endTransmission().
  void beginTransmission(int address) {
    // TODO: implement
  }
  void beginTransmission(uint8_t address) {
    beginTransmission((int)address);
  }

  // https://www.arduino.cc/en/Reference/WireEndTransmission
  // Ends a transmission to a slave device that was begun by beginTransmission() and transmits the bytes that were
  // queued by write().
  uint8_t endTransmission(uint8_t sendStop) {
    // TODO: implement
    return 0; // success
  }
  uint8_t endTransmission(void) {
    return endTransmission((uint8_t)true);
  }

  // https://www.arduino.cc/en/Reference/WireRequestFrom
  // Used by the master to request bytes from a slave device. The bytes may then be retrieved with the
  // available() and read() functions.
  uint8_t requestFrom(int address, int quantity, int stop) {
    // TODO: implement
    return 0; // number of bytes returned from the slave device
  }
  uint8_t requestFrom(int address, int quantity) {
    int stop = true;
    return requestFrom(address, quantity, stop);
  }
  uint8_t requestFrom(uint8_t address, uint8_t quantity) {
    return requestFrom((int)address, (int)quantity);
  }
  uint8_t requestFrom(uint8_t address, uint8_t quantity, uint8_t stop) {
    return requestFrom((int)address, (int)quantity, (int)stop);
  }
  uint8_t requestFrom(uint8_t, uint8_t, uint32_t, uint8_t, uint8_t) {
    // TODO: implement
    return 0;
  }

  // https://www.arduino.cc/en/Reference/WireWrite
  // Writes data from a slave device in response to a request from a master, or queues bytes for transmission from a
  // master to slave device (in-between calls to beginTransmission() and endTransmission()).
  size_t write(uint8_t value) {
    // TODO: implement
    return 0; // number of bytes written
  }
  size_t write(const char *str) { return str == NULL ? 0 : write((const uint8_t *)str, String(str).length()); }
  size_t write(const uint8_t *buffer, size_t size) {
    size_t n;
    for (n = 0; size && write(*buffer++) && ++n; --size);
    return n;
  }
  size_t write(const char *buffer, size_t size) { return write((const uint8_t *)buffer, size); }
  size_t write(unsigned long n) { return write((uint8_t)n); }
  size_t write(long n) { return write((uint8_t)n); }
  size_t write(unsigned int n) { return write((uint8_t)n); }
  size_t write(int n) { return write((uint8_t)n); }

  // https://www.arduino.cc/en/Reference/WireAvailable
  // Returns the number of bytes available for retrieval with read(). This should be called on a master device after a
  // call to requestFrom() or on a slave inside the onReceive() handler.
  int available(void) {
    // TODO: implement
    return 0; // number of bytes available for reading
  }

  // https://www.arduino.cc/en/Reference/WireRead
  // Reads a byte that was transmitted from a slave device to a master after a call to requestFrom() or was transmitted
  // from a master to a slave. read() inherits from the Stream utility class.
  int read(void) {
    // TODO: implement
    return '\0'; // The next byte received
  }
  int peek(void) {
    // TODO: implement
    return 0;
  }
  void flush(void) {
    // TODO: implement
  }

  // https://www.arduino.cc/en/Reference/WireOnReceive
  // Registers a function to be called when a slave device receives a transmission from a master.
  void onReceive( void (*callback)(int) ) {
    // TODO: implement
  }

  // https://www.arduino.cc/en/Reference/WireOnRequest
  // Register a function to be called when a master requests data from this slave device.
  void onRequest( void (*callback)(void) ) {
    // TODO: implement
  }

private:
  int i2cAddress;
  bool isMaster = false;
};

extern TwoWire Wire;
