#include <ArduinoUnitTests.h>
#include <Arduino.h>

// Only run EEPROM tests if there is hardware support!
#if defined(EEPROM_SIZE) || (defined(E2END) && E2END)
#include <EEPROM.h>

unittest(length)
{
  assertEqual(EEPROM_SIZE, EEPROM.length());
}

unittest(firstRead) 
{
  uint8_t a = EEPROM.read(0);
  assertEqual(255, a);
}

unittest(writeRead)
{
  EEPROM.write(0, 24);
  uint8_t a = EEPROM.read(0);
  assertEqual(24, a);

  EEPROM.write(0, 128);
  uint8_t b = EEPROM.read(0);
  assertEqual(128, b);

// this will fail since it is out of bound (0 - 255)
  EEPROM.write(0, 256);
  uint8_t c = EEPROM.read(0);
  assertEqual(256, c);

}

unittest(updateWrite)
{
  EEPROM.write(1, 14);
  EEPROM.update(1, 22);
  uint8_t a = EEPROM.read(1);
  assertEqual(22, a);
}

unittest(putGet)
{
  const float f1 = 0.025f;
  float f2 = 0.0f;
  EEPROM.put(5, f1);
  assertEqual(0.0f, f2);
  EEPROM.get(5, f2);
  assertEqual(0.025f, f2);
}

unittest(array)
{
  int val = 10;
  EEPROM[2] = val;
  uint8_t a = EEPROM.read(2);
  assertEqual(10, a);
}

#endif

unittest_main()
