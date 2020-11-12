#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(binary)
{
  assertEqual(1, B1);
  assertEqual(10, B1010);
  assertEqual(100, B1100100);
}

#ifdef __AVR__
#define DDRE      _SFR_IO8(0x02)

 unittest(SFR_IO8)
 {
   // in normal arduino code, you can do this.  in arduino_ci, you might get an
   // error like: cannot take the address of an rvalue of type 'int'
   //
   // this tests that directly
   auto foo = &DDRE;  // avoid compiler warning by using the result of an expression
 }

unittest(read_write)
{
  _SFR_IO8(1) = 0x11;
  _SFR_IO8(2) = 0x22;
  assertEqual((int) 0x11, (int) _SFR_IO8(1));
  assertEqual((int) 0x22, (int) _SFR_IO8(2));
  assertEqual((int) 0x2211, (int) _SFR_IO16(1));
}
#endif

unittest_main()
