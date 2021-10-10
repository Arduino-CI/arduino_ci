#include <ArduinoUnitTests.h>
#include <Arduino.h>

#define ARRAY_SIZEOF(a) ( sizeof(a) / sizeof((a)[0]) )

unittest(library_tests_itoa)
{
  char buf[32];
  const char *result;
  struct {
    int value;
    const char *expected;
    int base;
  } table[] = {
    { 54325, "1101010000110101", 2 },
    { 54325, "54325", 10 },
    { 54325, "D435", 16 },
    { 493, "755", 8 },
    { -1, "-1", 10 },
    { 32767, "32767", 10},
    { 32767, "7FFF", 16},
    { 65535, "65535", 10},
    { 65535, "FFFF", 16},
    { 2147483647, "2147483647", 10},
    { 2147483647, "7FFFFFFF", 16},
  };

  for (int i = 0; i < ARRAY_SIZEOF(table); i++) {
    result = itoa(table[i].value, buf, table[i].base);
    assertEqual(table[i].expected, result);
  }

  // While only bases 2, 8, 10 and 16 are of real interest, lets test that all
  // bases at least produce expected output for a few test points simple to test.
  for (int base = 2; base <= 16; base++) {
    result = itoa(0, buf, base);
    assertEqual("0", result);
    result = itoa(1, buf, base);
    assertEqual("1", result);
    result = itoa(base, buf, base);
    assertEqual("10", result);
  }

}

unittest(library_tests_dtostrf)
{
  float num = 123.456;
  char buffer[10];
  dtostrf(num, 7, 3, buffer);
  assertEqual(strncmp(buffer, "123.456", sizeof(buffer)), 0);
}

unittest_main()
