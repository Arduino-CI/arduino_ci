#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <vector>

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

    Wire.endTransmission(true);
    assertTrue(Wire.isTxBufferEmpty());
    assertEqual(0x07, Wire.getWriteDataElement(0));
    assertEqual(0x0E, Wire.getWriteDataElement(1));
}

// want to add read test, though it seems to depend on requestFrom




unittest_main()