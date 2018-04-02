#pragma once
#include "Godmode.h"
#include "WString.h"
#include "Print.h"

// This enumeration provides the lookahead options for parseInt(), parseFloat()
// The rules set out here are used until either the first valid character is found
// or a time out occurs due to lack of input.
enum LookaheadMode{
    SKIP_ALL,       // All invalid characters are ignored.
    SKIP_NONE,      // Nothing is skipped, and the stream is not touched unless the first waiting character is valid.
    SKIP_WHITESPACE // Only tabs, spaces, line feeds & carriage returns are skipped.
};

#define NO_IGNORE_CHAR  '\x01' // a char not found in a valid ASCII numeric field

class Stream : public Print
{
  public:
    String* mGodmodeDataIn;
    unsigned long* mGodmodeMicrosDelay;

  protected:
    unsigned long mTimeoutMillis;

    void fastforward(int pos) {
      mGodmodeDataIn->assign(mGodmodeDataIn->substring(pos));
    }

    char fastforwardToAnyChar(LookaheadMode lookahead, String chars) {
      char c;
      while ((c = peek()) != -1) {
        if (chars.find(c) != String::npos) return c;
        if (lookahead == SKIP_NONE) return -1;
        if (lookahead == SKIP_WHITESPACE && !isWhitespace(c)) return -1;
        read();
      }
      return -1;
    }

    // int timedRead();    // read stream with timeout
    // int timedPeek();    // peek stream with timeout
    // int peekNextDigit(LookaheadMode lookahead, bool detectDecimal); // returns the next numeric digit in the stream or -1 if timeout

  public:
    virtual int available() { return mGodmodeDataIn->length(); }

    virtual int peek() { return available() ? (int)((*mGodmodeDataIn)[0]) : -1; }

    virtual int read() {
      int ret = peek();
      if (ret != -1) {
        fastforward(1);
        if (mGodmodeMicrosDelay) delayMicroseconds(*mGodmodeMicrosDelay);
      }
      return ret;
    }

    // https://stackoverflow.com/a/4271276
    using Print::write;

    virtual size_t write(uint8_t aChar) { mGodmodeDataIn->append(String((char)aChar)); return 1; }

    Stream() {
      mTimeoutMillis = 1000;
      mGodmodeMicrosDelay = NULL;
      mGodmodeDataIn = NULL;
    }


    void setTimeout(unsigned long timeoutMillis) { mTimeoutMillis = timeoutMillis; };
    unsigned long getTimeout(void) { return mTimeoutMillis; }

    bool find(const String &s) {
      long idx;
      if ((idx = mGodmodeDataIn->find(s)) != String::npos) {
        fastforward(idx);
        return true;
      }
      return false;
    }

    bool find(char *target)                   { return find(String(target)); }
    bool find(uint8_t *target)                { return find(String((char*)target)); }
    bool find(char *target, size_t length)    { return find(String(string(target, length))); }
    bool find(uint8_t *target, size_t length) { return find(String(string((char*)target, length))); }
    bool find(char target)                    { return find(String(string(&target, 1))); }

    bool findUntil(const String &target, const String &terminator) {
      long idxTgt = mGodmodeDataIn->find(target);
      long idxTrm = mGodmodeDataIn->find(terminator);
      if (idxTgt == String::npos) {
        mGodmodeDataIn->clear();
        return false; // didn't find it
      }
      if (idxTrm != String::npos || idxTrm < idxTgt) {
        fastforward(idxTrm);
        return false;  // target found after term
      }
      return find(target);
    }

    bool findUntil(char *target, char *terminator)    { return findUntil(String(target), String(terminator)); }
    bool findUntil(uint8_t *target, char *terminator) { return findUntil(String((char *)target), String(terminator)); }
    bool findUntil(char *target, size_t targetLen, char *terminate, size_t termLen) {
      return findUntil(String(string(target, targetLen)), String(string(terminate, termLen)));
    }
    bool findUntil(uint8_t *target, size_t targetLen, char *terminate, size_t termLen) {
      return findUntil(String(string((char *)target, targetLen)), String(string(terminate, termLen)));
    }

    // returns the first valid (long) integer value from the current position.
    // lookahead determines how parseInt looks ahead in the stream.
    // See LookaheadMode enumeration at the top of the file.
    // Lookahead is terminated by the first character that is not a valid part of an integer.
    // Once parsing commences, 'ignore' will be skipped in the stream.
    long parseInt(LookaheadMode lookahead = SKIP_ALL, char ignore = NO_IGNORE_CHAR) {
      String digits = "1234567890";
      if (fastforwardToAnyChar(lookahead, digits + "-") == -1) return 0;
      String out = String((char)read()); // read unconditionally -- might be a minus
      char c;
      bool keepGoing = true;
      do {
        c = peek();
        if (c == -1) break;
        if (c != ignore || ignore == NO_IGNORE_CHAR) out += c;
        keepGoing = digits.find(c) != String::npos;
        if (!keepGoing) break;
        read();
      } while (true);
      return out.toInt();
    }

    float parseFloat(LookaheadMode lookahead = SKIP_ALL, char ignore = NO_IGNORE_CHAR) {
      String digits = "1234567890";
      if (fastforwardToAnyChar(lookahead, digits + "-") == -1) return 0;
      String out = String((char)read()); // read unconditionally -- might be a minus
      String bank = digits + ".";
      bool gotDot = false;
      bool keepGoing = true;
      char c;
      do {
        c = peek();
        if (c == -1) break;
        if (c == '.') {       // waiting for gotDot
          if (gotDot) break;
          gotDot = true;
        }
        if (c != ignore || ignore == NO_IGNORE_CHAR) out += c;
        keepGoing = bank.find(c) != String::npos;
        if (!keepGoing) break;
        read();
      } while (true);
      return out.toFloat();
    }

    // read chars from stream into buffer
    // returns the number of characters placed in the buffer (0 means no valid data found)
    size_t readBytes(char *buffer, size_t length) {
      size_t ret = mGodmodeDataIn->copy(buffer, length);
      if (mGodmodeMicrosDelay) delayMicroseconds(*mGodmodeMicrosDelay * ret);
      fastforward(ret);
      return ret;
    }

    // read chars from stream into buffer
    // returns the number of characters placed in the buffer (0 means no valid data found)
    size_t readBytes(uint8_t *buffer, size_t length) { return readBytes((char *)buffer, length); }

    // read chars from stream into buffer
    // returns the number of characters placed in the buffer (0 means no valid data found)
    size_t readBytesUntil(char terminator, char *buffer, size_t length) {
      size_t idx = mGodmodeDataIn->find(terminator);
      size_t howMuch = idx == String::npos ? length : min(length, idx);
      return readBytes(buffer, howMuch);
    }

    // read chars from stream into buffer
    // returns the number of characters placed in the buffer (0 means no valid data found)
    size_t readBytesUntil(char terminator, uint8_t *buffer, size_t length) { return readBytesUntil(terminator, (char *)buffer, length); }

    String readStringUntil(char terminator) {
      long idxTrm = mGodmodeDataIn->find(terminator);
      String ret;
      if (idxTrm == String::npos) {
        ret = String(*mGodmodeDataIn);
        mGodmodeDataIn->clear();
      } else {
        ret = mGodmodeDataIn->substring(0, idxTrm + 1);
        fastforward(idxTrm + 1);
      }
      return ret;
    }

    String readString() {
      String ret(*mGodmodeDataIn);
      mGodmodeDataIn->clear();
      return ret;
    }


  protected:
    long parseInt(char ignore) { return parseInt(SKIP_ALL, ignore); }
    float parseFloat(char ignore) { return parseFloat(SKIP_ALL, ignore); }
    // These overload exists for compatibility with any class that has derived
    // Stream and used parseFloat/Int with a custom ignore character. To keep
    // the public API simple, these overload remains protected.

};

#undef NO_IGNORE_CHAR


