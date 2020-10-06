#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <EEPROM.h>

#ifdef EEPROM_SIZE

unittest(length)
{
  assertEqual(EEPROM_SIZE, EEPROM.length());
}

#endif

unittest_main()
