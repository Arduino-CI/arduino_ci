#include <Arduino.h>
#include <ArduinoUnitTests.h>
#include <avr/wdt.h>

unittest(wdt) {
  wdt_disable();
  wdt_enable(WDTO_8S);
  wdt_reset();
  assertTrue(true);
}

unittest_main()
