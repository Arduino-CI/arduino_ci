#include <ArduinoUnitTests.h>
#include <Arduino.h>

class LcdInterface {
  public:
  virtual void print(const char *) = 0;
};

class MockLcd : public LcdInterface {
  public:
    String s;
    void print(const char* c)
    {
      s = String(c);
    }
};

class Calculator {
  private:
    LcdInterface *m_lcd;

  public:
    Calculator(LcdInterface* lcd) {
      m_lcd = lcd;
    }

    ~Calculator() {
      m_lcd = 0;
    }

    int add(int a, int b)
    {
      int result = a + b;
      char buf[40];
      sprintf(buf, "%d + %d = %d", a, b, result);
      m_lcd->print(buf);
      return result;
  }
};


// This is a typical test where using setup (and teardown) would be useful
// to set up the "external" lcd dependency that the calculator uses indirectly
// but it is not something that is related to the functionality that is tested.

MockLcd* lcd_p;
Calculator* c;

unittest_setup()
{
  lcd_p = new MockLcd();
  c = new Calculator(lcd_p);
}

unittest_teardown()
{
  delete c;
  delete lcd_p;
}


// When you want to test that the calculator actually prints the calculations,
// then that should be done in the arrange part of the actual test (by setting
// up an mock lcd class that keeps a list of all messages printed).

unittest(add)
{
  int result = c->add(11, 22);
  assertEqual(33, result);
  assertEqual("11 + 22 = 33", lcd_p->s);
}

unittest_main()
