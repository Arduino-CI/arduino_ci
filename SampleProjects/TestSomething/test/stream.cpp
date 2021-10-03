#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(stream_construction)
{
  String data = "";
  unsigned long micros = 100;

  Stream s;
  s.mGodmodeDataIn = &data;
  s.mGodmodeMicrosDelay = &micros;

  assertEqual(0, s.available());
  data = "abcd";
  assertEqual(4, s.available());
  assertEqual('a', s.peek());
  assertEqual('a', s.read());
  assertEqual("bcd", s.readString());
  assertEqual("", s.readString());

}


unittest(stream_find)
{
  String data = "";
  unsigned long micros = 100;

  Stream s;
  s.mGodmodeDataIn = &data;
  s.mGodmodeMicrosDelay = &micros;

  data = "abcdefghijkl";
  assertEqual('a', s.peek());
  assertEqual(true, s.find('f'));
  assertEqual('f', s.peek());
  assertEqual("fghijkl", s.readString());
  data = "fghijkl";
  assertEqual(false, s.findUntil("k", "j"));
  assertEqual('j', s.peek());
}

unittest(stream_parse)
{
  String data = "";
  unsigned long micros = 100;

  Stream s;
  s.mGodmodeDataIn = &data;
  s.mGodmodeMicrosDelay = &micros;

  long l;
  float f;
  data = "abcdefghijkl-123-456abcd";
  l = s.parseInt();
  assertEqual(-123, l);
  assertEqual('-', data[0]);
  l = s.parseInt();
  assertEqual(-456, l);
  l = s.parseInt();
  assertEqual(0, l);

  data = "abc123.456-345.322";
  f = s.parseFloat();
  assertLess(123.456 - f, 0.0001);
  assertEqual('-', data[0]);
  f = s.parseFloat();
  assertLess(-345.322 - f, 0.0001);

}

unittest(readStringUntil) {
  String data = "";
  unsigned long micros = 100;
  data = "abc:def";

  Stream s;
  s.mGodmodeDataIn = &data;
  s.mGodmodeMicrosDelay = &micros;
  // result should not include delimiter
  assertEqual("abc", s.readStringUntil(':'));
  assertEqual("def", s.readStringUntil(':'));
}
unittest_main()
