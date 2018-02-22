#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(string_constructors)
{
  assertTrue(String(""));
  assertTrue(String(3));
  assertTrue(String(3L));
  assertTrue(String(String("hi")));
  assertTrue(String(3.4));
}

unittest(string_assignment_and_misc)
{
  String s;
  s = String("");
  assertEqual(0, s.length());
  s = String("hi");
  assertEqual(2, s.length());
  s += String(" there ");
  assertEqual("hi there ", s);
  s.concat(-10);
  assertEqual("hi there -10", s);
  s.reserve(40);
  assertEqual("hi there -10", s);
  assertTrue(String("FOO").equalsIgnoreCase(String("foo")));
  assertFalse(String("F00").equalsIgnoreCase(String("foo")));
  assertEqual('i', s[1]);
  assertEqual('i', s.charAt(1));
  s[1] = 'o';
  assertEqual("ho there -10", s);
  s.setCharAt(1, 'i');
  assertEqual("hi there -10", s);

  s += " ";
  s += -3.141;
  assertEqual("hi there -10 -3.14", s);

  s.reserve(100);
  s.reserve(200);
  s.reserve(100);
}

unittest(string_comparison)
{
  assertEqual("-32768",      String(-32768));
  assertEqual("65535",       String(65535U));
  assertEqual("32767",       String(32767));
  assertEqual("2147483647",  String(2147483647L));
  assertEqual("-2147483648", String(-2147483648L));
  assertEqual("4294967295",  String(4294967295UL));
  assertEqual("3.14", String(3.1415, 2));
  assertEqual("-3.14", String(-3.1415, 2));
  assertEqual("0.14", String(0.1415, 2));
  assertEqual("0.14", String(-0.1415, 2));

  assertNotEqual(String("32767"), String(-32767));
  assertLess(String("a"), String("b"));

  assertEqual(-32768,      String(-32768).toInt());
  assertEqual(65535U,       String(65535U).toInt());
  assertEqual(32767,       String(32767).toInt());
  assertEqual(2147483647L,  String(2147483647L).toInt());
  assertEqual(-2147483648L, String(-2147483648L).toInt());
  assertEqual(4294967295UL,  String(4294967295UL).toInt());
  //assertEqual("3.141", String(3.1415));
}

unittest(string_mods)
{
  String s = "  hey  ";
  s.trim();
  assertEqual("hey", s);
  s.trim();
  assertEqual("hey", s);
  s = "";
  s.trim();
  assertEqual("", s);

  // https://www.arduino.cc/en/Tutorial/StringRemove
  s = "Hello World!";
  s.remove(7);
  assertEqual("Hello W", s);
  s = "Hello World!";
  s.remove(2, 6);
  assertEqual("Herld!", s);
}

unittest(string_find)
{
  String s = "in for a penny, in for a pound";
  assertEqual(3, s.indexOf('f'));
  assertEqual(3, s.indexOf("for"));
  assertEqual(19, s.indexOf('f', 7));
  assertEqual(19, s.indexOf("for", 7));
  assertEqual(19, s.lastIndexOf('f'));
  assertEqual(19, s.lastIndexOf("for"));
  assertEqual("a penny", s.substr(7, 7));

  assertTrue(s.startsWith("in for a penny"));
  assertTrue(s.startsWith("for a penny", 3));
  assertTrue(s.endsWith("in for a pound"));
  s.replace('i', 'o');
  assertEqual("on for a penny, on for a pound", s);
  s.replace("for a", "the");
  assertEqual("on the penny, on the pound", s);
  s.replace("p", "BRILLIANT");
  assertEqual("on the BRILLIANTenny, on the BRILLIANTound", s);
  s.replace("BRILLIANT", "p");
  assertEqual("on the penny, on the pound", s);
  s.replace("on the ", "");
  assertEqual("penny, pound", s);

  // infinite loop test
  String e = "zuzu";
  e.replace("zu", "zuzu");
  assertEqual("zuzuzuzu", e);

  // infinite loop test
  String i = "ii";
  i.replace('i', 'i');
  assertEqual("ii", i);
}


unittest_main()
