#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <vector>

#include <Wire.h>

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
    assertEqual(14, txAddress);
    
    assertTrue(Wire.getTxBuffer().empty());

    Wire.write(0x07);
    Wire.write(0x0E);
    assertEqual(0x07, getTxBuffer().at(0));
    assertEqual(0x0E, getTxBuffer().at(1));

    Wire.endTransmission(true);
    assertTrue(txBuffer.empty());
    assertEqual(0x07, getWriteData.at(0));
    assertEqual(0x0E, getWriteData.at(1));
}

// want to add read test, though it seems to depend on requestFrom




unittest_main()