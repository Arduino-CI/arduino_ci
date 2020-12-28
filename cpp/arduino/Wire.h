/*
 * The Wire Library (https://www.arduino.cc/en/Reference/Wire)
 * allows you to communicate with I2C/TWI devices. The general
 * TWI protocol supports one "master" device and many "slave"
 * devices that share the same two wires (SDA and SCL for data
 * and clock respectively).
 *
 * You initialize the library by calling begin() as a master or
 * begin(myAddress) as a slave (with an int from 8-127). In the
 * initial mock implementation we support only the master role.
 *
 * To send bytes from a master to a slave, start with
 * beginTransmission(slaveAddress), then use write(byte) to
 * enqueue data, and finish with endTransmission().
 *
 * When a master wants to read, it starts with a call to
 * requestFrom(slaveAddress, quantity) which blocks until the
 * request finishes. The return value is either 0 (if the slave
 * does not respond) or the number of bytes requested (which
 * might be more than the number sent since reading is simply
 * looking at a pin value at each clock tick).
 *
 * A master can write to or read from two or more slaves in
 * quick succession (say, during one loop() function), so our
 * mock needs to support preloading data to be read from multiple
 * slaves and archive data sent to multiple slaves.
 *
 * In the mock, this is handled by having an array of wireData_t
 * structures, each of which contains a deque for input and a
 * deque for output. You can preload data to be read and you can
 * look at a log of data that has been written.
 */

#pragma once

#include <inttypes.h>
#include "Stream.h"
#include <cassert>
#include <deque>
using std::deque;

const size_t SLAVE_COUNT = 128;
const size_t BUFFER_LENGTH = 32;

struct wireData_t {
  uint8_t misoSize;          // bytes remaining for this read
  uint8_t mosiSize;          // bytes included in this write
  deque<uint8_t> misoBuffer; // master in, slave out
  deque<uint8_t> mosiBuffer; // master out, slave in
};

// Some inspiration taken from
// https://github.com/arduino/ArduinoCore-megaavr/blob/d2a81093ba66d22dbda14c30d146c231c5910734/libraries/Wire/src/Wire.cpp
class TwoWire : public ObservableDataStream {
private:
  bool _didBegin = false;
  wireData_t* in = nullptr;  // pointer to current slave for writing
  wireData_t* out = nullptr; // pointer to current slave for reading
  wireData_t slaves[SLAVE_COUNT];

public:

  //////////////////////////////////////////////////////////////////////////////////////////////
  // testing methods
  //////////////////////////////////////////////////////////////////////////////////////////////

  // initialize all the mocks
  void resetMocks() {
    _didBegin = false;
    in = nullptr;  // pointer to current slave for writing
    out = nullptr; // pointer to current slave for reading
    for (int i = 0; i < SLAVE_COUNT; ++i) {
      slaves[i].misoSize = 0;
      slaves[i].mosiSize = 0;
      slaves[i].misoBuffer.clear();
      slaves[i].mosiBuffer.clear();
    }
  }

  // to verify that Wire.begin() was called at some point
  bool didBegin() { return _didBegin; }

  // to access the MISO buffer, which allows you to mock what the master will read in a request
  deque<uint8_t>* getMiso(uint8_t address) {
    return &slaves[address].misoBuffer;
  }

  // to access the MOSI buffer, which records what the master sends during a write
  deque<uint8_t>* getMosi(uint8_t address) {
    return &slaves[address].mosiBuffer;
  }


  //////////////////////////////////////////////////////////////////////////////////////////////
  // mock implementation
  //////////////////////////////////////////////////////////////////////////////////////////////

  // constructor initializes internal data
  TwoWire() {
    resetMocks();
  }

  // https://www.arduino.cc/en/Reference/WireBegin
  // Initiate the Wire library and join the I2C bus as a master or slave. This
  // should normally be called only once.
  void begin() { begin(0); }
  void begin(uint8_t address) {
    assert(address == 0);
    _didBegin = true;
  }
  void begin(int address) { begin((uint8_t)address); }
  // NOTE: end() is not part of the published API so we ignore it
  void end() {}

  // https://www.arduino.cc/en/Reference/WireSetClock
  // This function modifies the clock frequency for I2C communication. I2C slave
  // devices have no minimum working clock frequency, however 100KHz is usually
  // the baseline.
  // Since the mock does not actually write pins we ignore this.
  void setClock(uint32_t clock) {}

  // https://www.arduino.cc/en/Reference/WireBeginTransmission
  // Begin a transmission to the I2C slave device with the given address.
  // Subsequently, queue bytes for transmission with the write() function and
  // transmit them by calling endTransmission().
  // For the mock we update our output to the proper destination.
  void beginTransmission(uint8_t address) {
    assert(_didBegin);
    assert(address > 0 && address < SLAVE_COUNT);
    assert(out == nullptr);
    out = &slaves[address];
    out->mosiSize = 0;
  }
  void beginTransmission(int address) { beginTransmission((uint8_t)address); }

  // https://www.arduino.cc/en/Reference/WireEndTransmission
  // Ends a transmission to a slave device that was begun by beginTransmission()
  // and transmits the bytes that were queued by write().
  // In the mock we just leave the bytes there in the buffer
  // to be read by the testing API and we ignore the sendStop.
  uint8_t endTransmission(bool sendStop) {
    assert(_didBegin);
    assert(out);
    out = nullptr;
    return 0; // success
  }
  uint8_t endTransmission(void) { return endTransmission(true); }

  // https://www.arduino.cc/en/Reference/WireRequestFrom
  // Used by the master to request bytes from a slave device. The bytes may then
  // be retrieved with the available() and read() functions.
  uint8_t requestFrom(uint8_t address, uint8_t quantity, uint32_t _iaddress, uint8_t _isize, uint8_t stop) {
    assert(_didBegin);
    assert(address > 0 && address < SLAVE_COUNT);
    assert(quantity <= BUFFER_LENGTH);
    in = &slaves[address];
    // do we have enough data in the input buffer
    if (quantity <= (in->misoBuffer).size()) { // enough data
      in->misoSize = quantity;
      return quantity;
    } else { // not enough data
      in->misoSize = 0;
      in = nullptr;
      return 0;
    }
  }

  uint8_t requestFrom(uint8_t address, uint8_t quantity, uint8_t stop) {
    return requestFrom((uint8_t)address, (uint8_t)quantity, (uint32_t)0, (uint8_t)0, (uint8_t)stop);
  }

  uint8_t requestFrom(uint8_t address, uint8_t quantity) {
    return requestFrom((uint8_t)address, (uint8_t)quantity, (uint8_t)true);
  }

  uint8_t requestFrom(int address, int quantity) {
    return requestFrom((uint8_t)address, (uint8_t)quantity, (uint8_t)true);
  }
  uint8_t requestFrom(int address, int quantity, int stop) {
    return requestFrom((uint8_t)address, (uint8_t)quantity, (uint8_t)stop);
  }

  // https://www.arduino.cc/en/Reference/WireWrite
  // Writes data from a slave device in response to a request from a master, or
  // queues bytes for transmission from a master to slave device (in-between
  // calls to beginTransmission() and endTransmission()).
  size_t write(uint8_t value) {
    assert(out);
    assert(++(out->mosiSize) <= BUFFER_LENGTH);
    (out->mosiBuffer).push_back(value);
    return 1; // number of bytes written
  }
  size_t write(const char *str) {
    return str == NULL ? 0 : write((const uint8_t *)str, String(str).length());
  }
  size_t write(const uint8_t *buffer, size_t size) {
    size_t n;
    for (n = 0; size && write(*buffer++) && ++n; --size)
      ;
    return n;
  }
  size_t write(const char *buffer, size_t size) {
    return write((const uint8_t *)buffer, size);
  }
  size_t write(unsigned long n) { return write((uint8_t)n); }
  size_t write(long n) { return write((uint8_t)n); }
  size_t write(unsigned int n) { return write((uint8_t)n); }
  size_t write(int n) { return write((uint8_t)n); }

  // https://www.arduino.cc/en/Reference/WireAvailable
  // Returns the number of bytes available for retrieval with read(). This
  // should be called on a master device after a call to requestFrom() or on a
  // slave inside the onReceive() handler.
  int available(void) {
    assert(in);
    return in->misoSize;
  }

  // https://www.arduino.cc/en/Reference/WireRead
  // Reads a byte that was transmitted from a slave device to a master after a
  // call to requestFrom() or was transmitted from a master to a slave. read()
  // inherits from the Stream utility class.
  // In the mock we simply return the next byte from the input buffer.
  uint8_t read(void) {
    uint8_t value = peek();
    --in->misoSize;
    in->misoBuffer.pop_front();
    return value; // The next byte received
  }

  // part of the Stream API
  uint8_t peek(void) {
    assert(in);
    assert(0 < in->misoSize);
    return in->misoBuffer.front(); // The next byte received
  }

  // part of the Stream API
  void flush(void) {
    // NOTE: commented out in the megaavr repository
    // data already at the (mock) destination
  }

  // https://www.arduino.cc/en/Reference/WireOnReceive
  // Registers a function to be called when a slave device receives a
  // transmission from a master.
  // We don't (yet) support the slave role in the mock
  void onReceive(void (*callback)(int)) { assert(false); }

  // https://www.arduino.cc/en/Reference/WireOnRequest
  // Register a function to be called when a master requests data from this
  // slave device.
  // We don't (yet) support the slave role in the mock
  void onRequest(void (*callback)(void)) { assert(false); }

};

extern TwoWire Wire;
