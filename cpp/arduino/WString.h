#pragma once

#include <stdlib.h>
#include <stdexcept>
#include <string.h>
#include <algorithm>
#include <iostream>
#include "AvrMath.h"
#include "WCharacter.h"

typedef std::string string;

// work around some portability issues
#if defined(__clang__)
  #define ARDUINOCI_ISNAN isnan
  #define ARDUINOCI_ISINF isinf
#elif defined(__GNUC__) || defined(__GNUG__)
  #define ARDUINOCI_ISNAN std::isnan
  #define ARDUINOCI_ISINF std::isinf
#elif defined(_MSC_VER)
  // TODO: no idea
  #define ARDUINOCI_ISNAN ::isnan
  #define ARDUINOCI_ISINF ::isinf
#else
  #define ARDUINOCI_ISNAN ::isnan
  #define ARDUINOCI_ISINF ::isinf
#endif

class __FlashStringHelper;
#define F(string_literal) (reinterpret_cast<const __FlashStringHelper *>(PSTR(string_literal)))

// Compatibility with string class
class String: public string
{
  private:
    static const char *digit(int val)
    {
      static const char *bank = "0123456789ABCDEF";
      return bank + val;
    }

    static string mytoa(unsigned long val, int base) {
      int n = val % base;
      string place = string(digit(n), 1);
      if (val < base) return place;
      return mytoa(val / base, base) + place;
    }

    static string mytoas(long val, int base) {
      string ret = mytoa(abs(val), base);
      return 0 <= val ? ret : string("-") + ret;
    }

    static string dtoas(double val, int decimalPlaces) {
      double r = 0.5 * pow(0.1, decimalPlaces); // make sure that integer truncation will properly round
      if (ARDUINOCI_ISNAN(val)) return "nan";
      if (ARDUINOCI_ISINF(val)) return "inf";
      val += val > 0 ? r : -r;
      if (val > 4294967040.0) return "ovf";
      if (val <-4294967040.0) return "ovf";
      return mytoas(val, 10) + "." + mytoa(abs(val - (long)val) * pow(10, decimalPlaces), 10);
    }

  public:
    ~String(void) {}
    String(const __FlashStringHelper *str): string((const char *)str) {}
    String(const char *cstr = ""): string(cstr) {}
    String(const string &str): string(str) {}
    String(const String &str): string(str) {}
    explicit String(char c): string(1, c) {}

    explicit String(unsigned char val, unsigned char base=10): string(mytoa(val, base)) {}
    explicit String(int val,           unsigned char base=10): string(mytoas(val, base)) {}
    explicit String(unsigned int val , unsigned char base=10): string(mytoa(val, base)) {}
    explicit String(long val,          unsigned char base=10): string(mytoas(val, base)) {}
    explicit String(unsigned long val, unsigned char base=10): string(mytoa(val, base)) {}
    explicit String(long long val,     unsigned char base=10): string(mytoas(val, base)) {}
    explicit String(unsigned long long val, unsigned char base=10): string(mytoa(val, base)) {}

    explicit String(float val,  unsigned char decimalPlaces=2): string(dtoas(val, decimalPlaces)) {}
    explicit String(double val, unsigned char decimalPlaces=2): string(dtoas(val, decimalPlaces)) {}

      operator bool() const {
        return true;
      }

    String & operator = (const String &rhs) { assign(rhs); return *this; }
    String & operator = (const string &rhs) { assign(rhs); return *this; }
    String & operator = (const char *cstr)  { assign(cstr); return *this; }
    String & operator = (const char c)      { assign(1, c); return *this; }

    unsigned char concat(const __FlashStringHelper *str) { append((const char *)str); return 1; }
    unsigned char concat(const String &str) { append(str); return 1; }
    unsigned char concat(const char *cstr)  { append(cstr); return 1; }
    unsigned char concat(char c)            { append(1, c); return 1; }
    unsigned char concat(unsigned char c)   { append(1, c); return 1; }
    unsigned char concat(int num)           { append(String(num)); return 1; }
    unsigned char concat(unsigned int num)  { append(String(num)); return 1; }
    unsigned char concat(long num)          { append(String(num)); return 1; }
    unsigned char concat(unsigned long num) { append(String(num)); return 1; }
    unsigned char concat(long long num)     { append(String(num)); return 1; }
    unsigned char concat(unsigned long long num) { append(String(num)); return 1; }
    unsigned char concat(float num)         { append(String(num)); return 1; }
    unsigned char concat(double num)        { append(String(num)); return 1; }

    String & operator += (const __FlashStringHelper *rhs) { concat(rhs);  return *this; }
    String & operator += (const String &rhs) { concat(rhs);  return *this; }
    String & operator += (const char *cstr)  { concat(cstr); return *this; }
    String & operator += (char c)            { concat(c);    return *this; }
    String & operator += (unsigned char num) { concat(num);  return *this; }
    String & operator += (int num)           { concat(num);  return *this; }
    String & operator += (unsigned int num)  { concat(num);  return *this; }
    String & operator += (long num)          { concat(num);  return *this; }
    String & operator += (unsigned long num) { concat(num);  return *this; }
    String & operator += (long long num)     { concat(num);  return *this; }
    String & operator += (unsigned long long num) { concat(num);  return *this; }
    String & operator += (float num)         { concat(num);  return *this; }
    String & operator += (double num)        { concat(num);  return *this; }


    int compareTo(const String &s) const { return compare(s); }
    unsigned char equals(const String &s) const { return compareTo(s) == 0; }
    unsigned char equals(const char *cstr) const { return compareTo(String(cstr)) == 0; }
    unsigned char equal(const String &s) const { return equals(s); }
    unsigned char equal(const char *cstr) const { return equals(cstr); }
    unsigned char equalsIgnoreCase(const String &s) const {
      String a = String(*this);
      String b = String(s);
      a.toUpperCase();
      b.toUpperCase();
      return a.compare(b) == 0;
    }

    unsigned char startsWith(const String &prefix) const { return find(prefix) == 0; }
    unsigned char startsWith(const String &prefix, unsigned int offset) const { return find(prefix, offset) == offset; }
    unsigned char endsWith(const String &suffix) const { return rfind(suffix) == length() - suffix.length(); }

    char charAt(unsigned int index) const {	return operator[](index); }
    void setCharAt(unsigned int index, char c) { (*this)[index] = c; }

    void getBytes(unsigned char *buf, unsigned int bufsize, unsigned int index=0) const { copy((char*)buf, bufsize, index); }
    void toCharArray(char *buf, unsigned int bufsize, unsigned int index=0) const
      { getBytes((unsigned char *)buf, bufsize, index); }

    int indexOf( char ch ) const                                   { return find(ch); }
    int indexOf( char ch, unsigned int fromIndex ) const           { return find(ch, fromIndex); }
    int indexOf( const String &str ) const                         { return find(str); }
    int indexOf( const String &str, unsigned int fromIndex ) const { return find(str, fromIndex); }
    int lastIndexOf( char ch ) const                                   { return rfind(ch); }
    int lastIndexOf( char ch, unsigned int fromIndex ) const           { return rfind(ch, fromIndex); }
    int lastIndexOf( const String &str ) const                         { return rfind(str); }
    int lastIndexOf( const String &str, unsigned int fromIndex ) const { return rfind(str, fromIndex); }
    String substring( unsigned int beginIndex ) const { return String(substr(beginIndex)); }
    String substring( unsigned int beginIndex, unsigned int endIndex ) const { return String(substr(beginIndex, endIndex)); }

    void replace(const String& target, const String& repl) {
      int i = 0;
      while ((i = find(target, i)) != npos) {
        assign(substr(0, i) + repl + substr(i + target.length()));
        i += repl.length();
      }
    }
    void replace(char target, char repl) {
      replace(String(target), String(repl));
    }
    void remove(unsigned int index) { assign(substr(0, index)); }
    void remove(unsigned int index, unsigned int count) { assign(substr(0, index) + substr(min(length(), index + count), count)); }
    void toLowerCase(void) { std::transform(begin(), end(), begin(), ::tolower); }
    void toUpperCase(void) { std::transform(begin(), end(), begin(), ::toupper); }

    void trim(void) {
      int b;
      int e;
      for (b = 0; b < length() && isSpace(charAt(b)); ++b);
      for (e = length() - 1; e > b && isSpace(charAt(e)); --e);
      assign(substr(b, e - b + 1));
    }

    float toFloat(void) const   { return std::stof(*this); }
    double toDouble(void) const { return std::stod(*this); }
    long toInt(void) const      {
      try {
        return std::stol(*this);
      } catch (std::out_of_range) {
        return std::stoll(*this);
      }
    }

};

inline std::ostream& operator << ( std::ostream& out, const String& bs ) {
  out << bs.c_str();
  return out;
}

