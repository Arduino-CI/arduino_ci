#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(binary)
{
  assertEqual(1, B1);
  assertEqual(10, B1010);
  assertEqual(100, B1100100);
}

#define DDRE      _SFR_IO8(0x02)

 unittest(SFR_IO8)
 {
   // in normal arduino code, you can do this.  in arduino_ci, you might get an
   // error like: cannot take the address of an rvalue of type 'int'
   //
   // this tests that directly
   &DDRE;
 }

unittest_main()
