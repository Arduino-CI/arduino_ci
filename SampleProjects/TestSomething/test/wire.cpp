#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <Wire.h>
using std::deque;

unittest(begin_write_end) {
    // master write buffer should be empty
    deque<uint8_t>* mosi = Wire.getMosi(14);
    assertEqual(0, mosi->size());
    
    // write some random data to random slave
    const uint8_t randomSlaveAddr = 14;
    const uint8_t randomData[] = { 0x07, 0x0E };
    Wire.begin();
    Wire.beginTransmission(randomSlaveAddr);
    Wire.write(randomData[0]);
    Wire.write(randomData[1]);
    Wire.endTransmission();

    // check master write buffer values
    assertEqual(2, mosi->size());
    assertEqual(randomData[0], mosi->front());
    mosi->pop_front();
    assertEqual(randomData[1], mosi->front());
    mosi->pop_front();
    assertEqual(0, mosi->size());
}

unittest(readTwo_writeOne) {
    Wire.begin();
    deque<uint8_t>* miso;
    // place some values on random slaves' read buffers
    const int randomSlaveAddr = 19, anotherRandomSlave = 34, yetAnotherSlave = 47;
    const uint8_t randomData[] = { 0x07, 0x0E }, moreRandomData[] = { 1, 4, 7 };
    miso = Wire.getMiso(randomSlaveAddr);
    miso->push_back(randomData[0]);
    miso->push_back(randomData[1]);
    miso = Wire.getMiso(anotherRandomSlave);
    miso->push_back(moreRandomData[0]);
    miso->push_back(moreRandomData[1]);
    miso->push_back(moreRandomData[2]);

    // check read buffers and read-related functions
    // request more data than is in input buffer
    assertEqual(0, Wire.requestFrom(randomSlaveAddr, 3));
    assertEqual(0, Wire.available());
    // normal use cases
    assertEqual(2, Wire.requestFrom(randomSlaveAddr, 2));
    assertEqual(2, Wire.available());
    assertEqual(randomData[0], Wire.read());
    assertEqual(1, Wire.available());
    assertEqual(randomData[1], Wire.read());
    assertEqual(0, Wire.available());
    assertEqual(3, Wire.requestFrom(anotherRandomSlave, 3));
    assertEqual(3, Wire.available());
    assertEqual(moreRandomData[0], Wire.read());
    assertEqual(2, Wire.available());
    assertEqual(moreRandomData[1], Wire.read());
    assertEqual(1, Wire.available());
    assertEqual(moreRandomData[2], Wire.read());
    assertEqual(0, Wire.available());

    // write some arbitrary values to a third slave
    Wire.beginTransmission(yetAnotherSlave);
    for (int i = 1; i < 4; i++) {
        Wire.write(i * 2);
    }
    Wire.endTransmission();

    // check master write buffer
    deque<uint8_t>* mosi = Wire.getMosi(yetAnotherSlave);
    const uint8_t expectedValues[] = { 2, 4, 6 };

    assertEqual(3, mosi->size());
    assertEqual(expectedValues[0], mosi->front());
    mosi->pop_front();
    assertEqual(2, mosi->size());
    assertEqual(expectedValues[1], mosi->front());
    mosi->pop_front();
    assertEqual(1, mosi->size());
    assertEqual(expectedValues[2], mosi->front());
    mosi->pop_front();
    assertEqual(0, mosi->size());
}

unittest_main()
