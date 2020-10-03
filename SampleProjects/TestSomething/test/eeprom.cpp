#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <EEPROM.h>

unittest(length)
{
  assertEqual(EEPROM_SIZE, EEPROM.length());
}

unittest_main()
