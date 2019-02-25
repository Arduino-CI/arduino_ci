#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(check_ADCSRA_read_write) {
  ADCSRA = 123;

  assertEqual(123, ADCSRA);
}

unittest_main()
