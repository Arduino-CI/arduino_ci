#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <EEPROM.h>

#ifdef EEPROM_SIZE

unittest(length)
{
  assertEqual(EEPROM_SIZE, EEPROM.length());
}

#else

unittest(eeprom)
{
  assertTrue(true);
}

#endif

unittest_main()
