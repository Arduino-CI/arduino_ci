#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <vector>
#include <map>

#include <Wire.h>
using namespace std;

unittest(beginAsMaster) {
    Wire.begin();
    assertTrue(Wire.getIsMaster());
}

unittest(beginAsSlave) {
    Wire.begin(13);
    assertFalse(Wire.getIsMaster());
}

unittest(getMasterAddress) {
    Wire.begin();
    assertEqual(0, Wire.getAddress());
}

unittest(getSlaveAddress) {
    Wire.begin(13);
    assertEqual(13, Wire.getAddress());
}

unittest(begin_write_end) {
    Wire.begin();
    Wire.beginTransmission(14);
    assertEqual(14, Wire.getAddress());
    
    assertTrue(Wire.isTxBufferEmpty());

    Wire.write(0x07);
    Wire.write(0x0E);
    assertEqual(0x07, Wire.getTxBufferElement(0));
    assertEqual(0x0E, Wire.getTxBufferElement(1));

    Wire.endTransmission();
    assertTrue(Wire.isTxBufferEmpty());

    vector<int> finalData = {0x07, 0x0E};
    assert(finalData == Wire.getDataWritten(14));
}

unittest(readTwo_writeOne) {
    Wire.begin();
    
    vector<int> data1 = {0x07, 0x0E}, data2 = {1, 4, 7};
    Wire.setDataToRead(19, data1);
    Wire.setDataToRead(34, data2);

    assertEqual(2, Wire.requestFrom(19, 1));
    assertEqual(3, Wire.requestFrom(34, 1));
    assertEqual(data1.size() + data2.size(), Wire.getRxBufferSize());

    Wire.beginTransmission(47);
    assertEqual(47, Wire.getAddress());
    assertTrue(Wire.isTxBufferEmpty());
    for (int i = 0; i < 5; i++) {
        Wire.write(Wire.read());
    }
    assertEqual(0x07, Wire.getTxBufferElement(0));
    assertEqual(0x0E, Wire.getTxBufferElement(1));
    assertEqual(1, Wire.getTxBufferElement(2));
    assertEqual(4, Wire.getTxBufferElement(3));
    assertEqual(7, Wire.getTxBufferElement(4));

    Wire.endTransmission();
    assertTrue(Wire.isTxBufferEmpty());

    vector<int> finalData = {0x07, 0x0E, 1, 4, 7};
    assert(finalData == Wire.getDataWritten(47));
}

unittest_main()