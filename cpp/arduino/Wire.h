
#pragma once

#include <inttypes.h>

// https://github.com/Arduino-CI/arduino_ci/issues/165
#ifdef max
#undef max
#ifdef __cplusplus
template <class T, class L>
auto max(const T &a, const L &b) -> decltype((b < a) ? b : a) {
  return (a < b) ? b : a;
}
#else
#define max(a, b)                                                              \
  ({                                                                           \
    __typeof__(a) _a = (a);                                                    \
    __typeof__(b) _b = (b);                                                    \
    _a > _b ? _a : _b;                                                         \
  })
#endif
#endif

// map is already defined in AvrMath.h. Need to use C++'s map.
#ifdef map
#undef map
#endif


#include <vector>
#include <map>
#include <cassert>
#include "Stream.h"

using std::vector;
using std::map;

// Some inspiration taken from https://github.com/arduino/ArduinoCore-megaavr/blob/d2a81093ba66d22dbda14c30d146c231c5910734/libraries/Wire/src/Wire.cpp
class TwoWire : public ObservableDataStream
{
public:
  TwoWire() {
  }

  // https://www.arduino.cc/en/Reference/WireBegin
  // Initiate the Wire library and join the I2C bus as a master or slave. This should normally be called only once.
  void begin() {
    isMaster = true;
    txAddress = 0;
  }
  void begin(int address) {
    txAddress = address;
    isMaster = false;
  }
  void begin(uint8_t address) {
    begin((int)address);
  }
  void end() {
    // TODO: implement
    // NOTE: unnecessary for current high level implementation
  }

  // https://www.arduino.cc/en/Reference/WireSetClock
  // This function modifies the clock frequency for I2C communication. I2C slave devices have no minimum working
  // clock frequency, however 100KHz is usually the baseline.
  void setClock(uint32_t clock) {
    // TODO: implement?
    // NOTE: unnecessary for current high level implementation
  }

  // https://www.arduino.cc/en/Reference/WireBeginTransmission
  // Begin a transmission to the I2C slave device with the given address. Subsequently, queue bytes for
  // transmission with the write() function and transmit them by calling endTransmission().
  void beginTransmission(int address) {
    assert(isMaster);
    txAddress = address;
    txBuffer.clear();
  }
  void beginTransmission(uint8_t address) {
    beginTransmission((int)address);
  }

  // https://www.arduino.cc/en/Reference/WireEndTransmission
  // Ends a transmission to a slave device that was begun by beginTransmission() and transmits the bytes that were
  // queued by write().
  uint8_t endTransmission(uint8_t sendStop) {
    assert(isMaster);
    int bufferSize = txBuffer.size();
    dataWritten[txAddress] = txBuffer;
    txBuffer.clear();
    // ensure separate objects
    assert(bufferSize == dataWritten[txAddress].size());
    txAddress = 0;
    return 0; // success
  }
  uint8_t endTransmission(void) {
    return endTransmission((uint8_t)true);
  }

  // https://www.arduino.cc/en/Reference/WireRequestFrom
  // Used by the master to request bytes from a slave device. The bytes may then be retrieved with the
  // available() and read() functions.
  uint8_t requestFrom(int address, int quantity, int stop) {
    // TODO: implement quantity and stop?
    assert(isMaster);
    
    int oldRxBufferLength = rxBuffer.size();
    // append vector to vector
    rxBuffer.insert(rxBuffer.end(), dataToRead[address].begin(), dataToRead[address].end());
    return rxBuffer.size()-oldRxBufferLength; // number of bytes returned from the slave device
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
    txBuffer.push_back(value);
    return 1; // number of bytes written
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
    return rxBuffer.size(); // number of bytes available for reading
  }

  // https://www.arduino.cc/en/Reference/WireRead
  // Reads a byte that was transmitted from a slave device to a master after a call to requestFrom() or was transmitted
  // from a master to a slave. read() inherits from the Stream utility class.
  int read(void) {
    // TODO: implement
    int value = -1;
    value = rxBuffer.at(0);
    rxBuffer.erase(rxBuffer.begin());
    return value; // The next byte received
  }
  int peek(void) {
    // TODO: implement
    int value = -1;
    value = rxBuffer.at(0);
    return 0;
  }
  void flush(void) {
    // TODO: implement
    // NOTE: commented out in the megaavr repository
    txBuffer.clear();
    rxBuffer.clear();
  }

  // https://www.arduino.cc/en/Reference/WireOnReceive
  // Registers a function to be called when a slave device receives a transmission from a master.
  void onReceive( void (*callback)(int) ) {
    // TODO: implement
    user_onReceive = callback;
  }

  // https://www.arduino.cc/en/Reference/WireOnRequest
  // Register a function to be called when a master requests data from this slave device.
  void onRequest( void (*callback)(void) ) {
    // TODO: implement
    user_onRequest = callback;
  }

  // testing methods
  bool getIsMaster() { return isMaster; }
  int getAddress() { return txAddress; }
  bool isTxBufferEmpty() { return txBuffer.empty(); }
  int getTxBufferElement(int index) { return txBuffer.at(index); }
  vector<int> getDataWritten(int address) { return dataWritten.at(address); }
  int getRxBufferSize() { return rxBuffer.size(); }
  void setDataToRead(int address, vector<int> data) { dataToRead[address] = data; }

private:
  bool isMaster = false;
  uint8_t txAddress;
  static void (*user_onReceive)(int);
  static void (*user_onRequest)(void);
  vector<int> txBuffer, rxBuffer;
  map<uint8_t, vector<int>> dataToRead, dataWritten;
};

extern TwoWire Wire;
