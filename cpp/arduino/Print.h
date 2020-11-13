#pragma once

#include <stdio.h>
#include <avr/pgmspace.h>

#include "Printable.h"
#include "WString.h"

#define DEC 10
#define HEX 16
#define OCT 8
#ifdef BIN
#undef BIN
#endif
#define BIN 2

class Print
{
  private:
    int write_error;
  protected:
    void setWriteError(int err = 1) { write_error = err; }
  public:
    Print() : write_error(0) {}

    int getWriteError() { return write_error; }
    void clearWriteError() { setWriteError(0); }
    virtual int availableForWrite() { return 0; }

    virtual size_t write(uint8_t) = 0;
    size_t write(const char *str) { return str == NULL ? 0 : write((const uint8_t *)str, String(str).length()); }

    virtual size_t write(const uint8_t *buffer, size_t size) {
      size_t n;
      for (n = 0; size && write(*buffer++) && ++n; --size);
      return n;
    }

    size_t write(const char *buffer, size_t size) { return write((const uint8_t *)buffer, size); }

    size_t print(const String &s)                 { return write(s.c_str(), s.length()); }
    size_t print(const __FlashStringHelper *str)  { return print(reinterpret_cast<PGM_P>(str)); }
    size_t print(const char* str)                 { return print(String(str)); }
    size_t print(char c)                          { return print(String(c)); }
    size_t print(unsigned char b, int base = DEC) { return print(String(b, base)); }
    size_t print(int n,           int base = DEC) { return print(String(n, base)); }
    size_t print(unsigned int n,  int base = DEC) { return print(String(n, base)); }
    size_t print(long n,          int base = DEC) { return print(String(n, base)); }
    size_t print(unsigned long n, int base = DEC) { return print(String(n, base)); }
    size_t print(double n,        int base = DEC) { return print(String(n, base)); }
    size_t print(const Printable& x)              { return x.printTo(*this); }

    size_t println(void)                              { return print("\r\n"); }
    size_t println(const String &s)                   { return print(s) + println(); }
    size_t println(const __FlashStringHelper *str)    { return println(reinterpret_cast<PGM_P>(str)); }
    size_t println(const char* c)                     { return println(String(c)); }
    size_t println(char c)                            { return println(String(c)); }
    size_t println(unsigned char b,   int base = DEC) { return println(String(b, base)); }
    size_t println(int num,           int base = DEC) { return println(String(num, base)); }
    size_t println(unsigned int num,  int base = DEC) { return println(String(num, base)); }
    size_t println(long num,          int base = DEC) { return println(String(num, base)); }
    size_t println(unsigned long num, int base = DEC) { return println(String(num, base)); }
    size_t println(double num,        int base = DEC) { return println(String(num, base)); }
    size_t println(const Printable& x)                { return print(x) + println(); }

    virtual void flush() { }

};
