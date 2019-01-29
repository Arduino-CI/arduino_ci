#include <ArduinoUnitTests.h>
#include <Arduino.h>

class LcdInterface {
  public:
  virtual void print(const char *) = 0;
};

class MockLcd : public LcdInterface {
  public:
  void print(const char *) {}
};

LcdInterface *Lcd_p;

class Calculator {
  public:
  int add(int a, int b) {
    int result = a + b;
    char buf[40];
    sprintf(buf, "%d + %d = %d", a, b, result);
    Lcd_p->print(buf);
    return result;
  }
};

unittest_setup()
{
  Lcd_p = new MockLcd();
}

unittest_teardown()
{
  delete Lcd_p;
}

// This is a typical test where using setup (and teardown) would be useful
// to set up the "external" lcd dependency that the calculator uses indirectly
// but it is not something that is related to the functionality that is tested.

// When you want to test that the calculator actually prints the calculations,
// then that should be done in the arrange part of the actual test (by setting
// up an mock lcd class that keeps a list of all messages printed).

unittest(add)
{
  // Arrange
  Calculator c;

  // Act
  int result = c.add(11, 22);

  // Assert
  assertEqual(33, result);
}

unittest_main()
