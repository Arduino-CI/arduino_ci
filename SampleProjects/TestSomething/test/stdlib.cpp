#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include <ctype.h>
#include <string.h>

#define ARRAY_SIZEOF(a) ( sizeof(a) / sizeof((a)[0]) )

unittest(library_tests_itoa)
{
  char buf[32];
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
    itoa(table[i].value, buf, table[i].base);
    for (int j = 0; j < strlen(buf); ++j) {
      buf[j] = toupper(buf[j]);
    }
    assertEqual(table[i].expected, buf);
  }

  // While only bases 2, 8, 10 and 16 are of real interest, let's test that all
  // bases at least produce expected output for a few test points simple to test.
  for (int base = 2; base <= 16; base++) {
    itoa(0, buf, base);
    assertEqual("0", buf);
    itoa(1, buf, base);
    assertEqual("1", buf);
    itoa(base, buf, base);
    assertEqual("10", buf);
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
