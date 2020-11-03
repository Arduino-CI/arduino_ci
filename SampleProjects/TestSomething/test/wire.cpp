#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <Wire.h>
using std::deque;

unittest(begin_write_end) {
    deque<uint8_t>* mosi = Wire.getMosi(14);
    assertEqual(0, mosi->size());
    Wire.begin();
    Wire.beginTransmission(14);
    Wire.write(0x07);
    Wire.write(0x0E);
    Wire.endTransmission();
    assertEqual(2, mosi->size());
    assertEqual(0x07, mosi->front());
    mosi->pop_front();
    assertEqual(0x0E, mosi->front());
    mosi->pop_front();
    assertEqual(0, mosi->size());
}

unittest(readTwo_writeOne) {
    Wire.begin();
    deque<uint8_t>* miso;
    miso = Wire.getMiso(19);
    miso->push_back(0x07);
    miso->push_back(0x0E);
    miso = Wire.getMiso(34);
    miso->push_back(1);
    miso->push_back(4);
    miso->push_back(7);

    assertEqual(0, Wire.requestFrom(19, 3));
    assertEqual(2, Wire.requestFrom(19, 2));
    assertEqual(2, Wire.available());
    assertEqual(0x07, Wire.read());
    assertEqual(1, Wire.available());
    assertEqual(0x0E, Wire.read());
    assertEqual(0, Wire.available());
    assertEqual(3, Wire.requestFrom(34, 3));
    assertEqual(3, Wire.available());
    assertEqual(1, Wire.read());
    assertEqual(2, Wire.available());
    assertEqual(4, Wire.read());
    assertEqual(1, Wire.available());
    assertEqual(7, Wire.read());
    assertEqual(0, Wire.available());

    Wire.beginTransmission(47);
    for (int i = 1; i < 4; i++) {
        Wire.write(i * 2);
    }
    Wire.endTransmission();
    deque<uint8_t>* mosi = Wire.getMosi(47);

    assertEqual(3, mosi->size());
    assertEqual(2, mosi->front());
    mosi->pop_front();
    assertEqual(2, mosi->size());
    assertEqual(4, mosi->front());
    mosi->pop_front();
    assertEqual(1, mosi->size());
    assertEqual(6, mosi->front());
    mosi->pop_front();
    assertEqual(0, mosi->size());
}

unittest_main()
