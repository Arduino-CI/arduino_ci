#include <ArduinoUnitTests.h>
#include <Arduino.h>

// Only run EEPROM tests if there is hardware support!
#if defined(EEPROM_SIZE) || (defined(E2END) && E2END)
#include <EEPROM.h>

unittest(length)
{
  assertEqual(EEPROM_SIZE, EEPROM.length());
}

#endif

unittest_main()
