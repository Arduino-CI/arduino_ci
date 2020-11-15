#include <ArduinoUnitTests.h>
#include <Arduino.h>

// added to fix https://github.com/Arduino-CI/arduino_ci/issues/193
// https://github.com/arduino-libraries/Ethernet/blob/master/src/utility/w5100.h#L337

#if defined(__AVR__)
unittest(portOutputRegister)
{
  uint8_t ss_pin = 12;
  uint8_t ss_port = digitalPinToPort(ss_pin);
  assertEqual(12, ss_port);
  uint8_t *ss_pin_reg = portOutputRegister(ss_port);
  assertEqual(GODMODE()->pMmapPort(ss_port), ss_pin_reg);
  uint8_t ss_pin_mask = digitalPinToBitMask(ss_pin);
  assertEqual(1, ss_pin_mask);

  assertEqual((int) 1, (int) *ss_pin_reg);    // verify initial value
  *(ss_pin_reg) &= ~ss_pin_mask;              // set SS
  assertEqual((int) 0, (int) *ss_pin_reg);    // verify value
  *(ss_pin_reg) |= ss_pin_mask;               // clear SS
  assertEqual((int) 1, (int) *ss_pin_reg);    // verify value
}

unittest(portInputRegister)
{
  uint8_t ss_pin = 12;
  uint8_t ss_port = digitalPinToPort(ss_pin);
  assertEqual(12, ss_port);
  uint8_t *ss_pin_reg = portInputRegister(ss_port);
  assertEqual(GODMODE()->pMmapPort(ss_port), ss_pin_reg);
  uint8_t ss_pin_mask = digitalPinToBitMask(ss_pin);
  assertEqual(1, ss_pin_mask);

  assertEqual((int) 1, (int) *ss_pin_reg);    // verify initial value
  *(ss_pin_reg) &= ~ss_pin_mask;              // set SS
  assertEqual((int) 0, (int) *ss_pin_reg);    // verify value
  *(ss_pin_reg) |= ss_pin_mask;               // clear SS
  assertEqual((int) 1, (int) *ss_pin_reg);    // verify value
}
#endif

unittest_main()
