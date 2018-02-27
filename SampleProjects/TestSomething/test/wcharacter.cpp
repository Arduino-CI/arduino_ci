#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(isAlpha)
{
  assertTrue(isAlpha('a'));
  assertFalse(isAlpha('3'));
}

unittest(isAlphaNumeric)
{
  assertTrue(isAlphaNumeric('a'));
  assertTrue(isAlphaNumeric('3'));
  assertFalse(isAlphaNumeric('!'));
}

unittest(isAscii)
{
  assertTrue(isAscii('a'));
  assertTrue(isAscii('3'));
  assertTrue(isAscii('!'));
  assertFalse(isAlpha((int)0xAF));
}

unittest(isControl)
{
  assertFalse(isControl(' '));
  assertTrue(isControl((int)0x03));
}

unittest(isDigit)
{
  assertFalse(isDigit(' '));
  assertTrue(isDigit('2'));
}

unittest(isGraph)
{
  assertFalse(isGraph(' '));
  assertTrue(isGraph('2'));
}

unittest(isHexadecimalDigit)
{
  assertTrue(isHexadecimalDigit('0'));
  assertTrue(isHexadecimalDigit('a'));
  assertTrue(isHexadecimalDigit('A'));
  assertFalse(isHexadecimalDigit('G'));
  assertFalse(isHexadecimalDigit('!'));
}

unittest(isLowerCase)
{
  assertFalse(isLowerCase('A'));
  assertTrue(isLowerCase('a'));
}

unittest(isPrintable)
{
  assertFalse(isPrintable((int)0x03));
  assertTrue(isPrintable('a'));
}

unittest(isPunct)
{
  assertFalse(isPunct('a'));
  assertTrue(isPunct('!'));
}

unittest(isSpace)
{
  assertFalse(isSpace('a'));
  assertTrue(isSpace(' '));
}

unittest(isUpperCase)
{
  assertFalse(isUpperCase('a'));
  assertTrue(isUpperCase('A'));
}

unittest(isWhitespace)
{
  assertTrue(isWhitespace(' '));
  assertTrue(isWhitespace('\r'));
  assertTrue(isWhitespace('\f'));
  assertTrue(isWhitespace('\t'));
  assertTrue(isWhitespace('\v'));
  assertTrue(isWhitespace('\n'));
  assertFalse(isWhitespace('j'));
}

unittest_main()
