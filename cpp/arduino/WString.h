#pragma once

#include <stdlib.h>
#include <string>
#include <algorithm>
#include <iostream>
#include "AvrMath.h"

typedef std::string string;


// Compatibility with string class
class String: public string
{
  public:

    // allow "string s; if (s) {}"
    // http://www.artima.com/cppsource/safebool.html
    typedef void (String::*TTDNSCstring)() const;
    void ttdnsc() const {}
    operator TTDNSCstring() const  { return &String::ttdnsc; }

  private:
    static const char* digit(int val) {
      const char* bank = "0123456789ABCDEF";
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

public:
  ~String(void) {}
  String(const char *cstr = ""): string(cstr) {}
  String(const string &str): string(str.c_str()) {}
  String(const String &str): string(str.c_str()) {}
  explicit String(char c): string(&c, 1) {}

  explicit String(unsigned char val, unsigned char base=10): string(mytoa(val, base)) {}
  explicit String(int val,           unsigned char base=10): string(mytoas(val, base)) {}
  explicit String(unsigned int val , unsigned char base=10): string(mytoa(val, base)) {}
  explicit String(long val,          unsigned char base=10): string(mytoas(val, base)) {}
  explicit String(unsigned long val, unsigned char base=10): string(mytoa(val, base)) {}

  explicit String(float val,  unsigned char decimalPlaces=2):
    string(mytoas(val, 10) + "." + mytoa(abs(val - (long)val) * pow(10, decimalPlaces), 10)) {}
  explicit String(double val, unsigned char decimalPlaces=2):
    string(mytoas(val, 10) + "." + mytoa(abs(val - (long)val) * pow(10, decimalPlaces), 10)) {}

  String & operator = (const String &rhs) { assign(rhs); return *this; }
  String & operator = (const char *cstr) { assign(cstr); return *this; }

	unsigned char reserve(unsigned int size) { return true; } // calling reserve(size) segfaults, no idea why

  unsigned char concat(const String &str) { append(str); return 1; }
  unsigned char concat(const char *cstr)  { append(cstr); return 1; }
  unsigned char concat(char c)            { append((const char*)&c, 1); return 1; }
  unsigned char concat(unsigned char c)   { append((const char*)&c, 1); return 1; }
  unsigned char concat(int num)           { append(String(num)); return 1; }
  unsigned char concat(unsigned int num)  { append(String(num)); return 1; }
  unsigned char concat(long num)          { append(String(num)); return 1; }
  unsigned char concat(unsigned long num) { append(String(num)); return 1; }
  unsigned char concat(float num)         { append(String(num)); return 1; }
  unsigned char concat(double num)        { append(String(num)); return 1; }

  String & operator += (const String &rhs) { concat(rhs);  return *this; }
  String & operator += (const char *cstr)  { concat(cstr); return *this; }
  String & operator += (char c)            { concat(c);    return *this; }
  String & operator += (unsigned char num) { concat(num);  return *this; }
  String & operator += (int num)           { concat(num);  return *this; }
  String & operator += (unsigned int num)  { concat(num);  return *this; }
  String & operator += (long num)          { concat(num);  return *this; }
  String & operator += (unsigned long num) { concat(num);  return *this; }
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

  long toInt(void) const      { return std::stol(*this); }
  float toFloat(void) const   { return std::stof(*this); }
  double toDouble(void) const { return std::stod(*this); }

};

template <typename T> inline std::ostream& operator << ( std::ostream& out, const std::basic_string<T>& bs ) {
  out << bs.c_str();
  return out;
}

inline std::ostream& operator << ( std::ostream& out, const String& bs ) {
  out << bs.c_str();
  return out;
}

