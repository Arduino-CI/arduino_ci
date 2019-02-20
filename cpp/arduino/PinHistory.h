#pragma once
#include "MockEventQueue.h"
#include "ci/ObservableDataStream.h"
#include "WString.h"

// pins with history.
template <typename T>
class PinHistory : public ObservableDataStream {
  private:
    MockEventQueue<T> qIn;
    MockEventQueue<T> qOut;

    void clear() {
      qOut.clear();
      qIn.clear();
    }

    // enqueue ascii bits
    void a2q(MockEventQueue<T> &q, String input, bool bigEndian, bool advertise) {
      // 8 chars at a time, form up
      for (int j = 0; j < input.length(); ++j) {
        for (int i = 0; i < 8; ++i) {
          int shift = bigEndian ? 7 - i : i;
          unsigned char mask = (0x01 << shift);
          q.push(mask & input[j]);
          if (advertise) advertiseBit(q.backData()); // not valid for all possible types but whatever
        }
      }
    }


    // convert a queue to a string as if it was serial bits
    // start from offset, consider endianness
    String q2a(const MockEventQueue<T> &q, unsigned int offset, bool bigEndian) const {
      String ret = "";

      MockEventQueue<T> q2(q);

      while (offset) {
        q2.pop();
        --offset;
      }

      if (offset) return ret;

      // 8 chars at a time, form up
      while (q2.size() >= 8) {
        unsigned char acc = 0x00;
        for (int i = 0; i < 8; ++i) {
          int shift = bigEndian ? 7 - i : i;
          T val = q2.frontData();
          unsigned char bit = val ? 0x1 : 0x0;
          acc |= (bit << shift);
          q2.pop();
        }
        ret.append(String((char)acc));
      }

      return ret;
    }

    void init() {
      asciiEncodingOffsetIn = 0;  // default is sensible
      asciiEncodingOffsetOut = 1; // default is sensible
    }

  public:
    unsigned int asciiEncodingOffsetIn;
    unsigned int asciiEncodingOffsetOut;

    PinHistory(unsigned long (*getMicros)(void)) : ObservableDataStream(), qOut(getMicros) {
      init();
    }

    PinHistory() : ObservableDataStream() {
      init();
    }

    void setMicrosRetriever(unsigned long (*getMicros)(void)) { qOut.setMicrosRetriever(getMicros); }

    void reset(T val) {
      clear();
      qOut.push(val);
    }

    unsigned int historySize() const { return qOut.size(); }

    unsigned int queueSize() const { return qIn.size(); }

    // This returns the "value" of the pin in a raw sense
    operator T() const {
      if (!qIn.empty()) return qIn.frontData();
      return qOut.backData();
    }

    // this sets the value of the pin authoritatively
    // so if there was a queue, dump it.
    // the actual "set" operation doesn't happen until the next read
    T operator=(const T& i) {
      qIn.clear();
      qOut.push(i);
      advertiseBit(qOut.backData()); // not valid for all possible types but whatever
      return qOut.backData();
    }

    // This returns the "value" of the pin according to the queued values
    // if there is input, advance it to the output.
    // then take the latest output.
    T retrieve() {
      if (!qIn.empty()) {
        T hack_required_by_travis_ci = qIn.frontData();
        qIn.pop();
        qOut.push(hack_required_by_travis_ci);
      }
      return qOut.backData();
    }

    // enqueue a set of data elements
    void fromArray(T const * const arr, unsigned int length) {
      for (int i = 0; i < length; ++i) qIn.push(arr[i]);
    }

    // enqueue ascii bits for future use by the retrieve() function
    void fromAscii(String input, bool bigEndian) { a2q(qIn, input, bigEndian, false); }

    // send a stream of ascii bits immediately
    void outgoingFromAscii(String input, bool bigEndian) { a2q(qOut, input, bigEndian, true); }

    // convert the queue of incoming data to a string as if it was Serial comms
    // start from offset, consider endianness
    String incomingToAscii(unsigned int offset, bool bigEndian) const { return q2a(qIn, offset, bigEndian); }

    // convert the queue of incoming data to a string as if it was Serial comms
    // start from offset, consider endianness
    String incomingToAscii(bool bigEndian) const { return incomingToAscii(asciiEncodingOffsetIn, bigEndian); }

    // convert the pin history data to a string as if it was Serial comms
    // start from offset, consider endianness
    String toAscii(unsigned int offset, bool bigEndian) const { return q2a(qOut, offset, bigEndian); }

    // convert the pin history data to a string as if it was Serial comms
    // start from offset, consider endianness
    String toAscii(bool bigEndian) const { return toAscii(asciiEncodingOffsetOut, bigEndian); }

    // copy data elements to an array, up to a given length
    // return the number of elements moved
    int toArray (T* arr, unsigned int length) const {
      MockEventQueue<T> q2(qOut);  // preserve const by copying

      int ret = 0;
      for (int i = 0; i < length && q2.size(); ++i) {
        arr[i] = q2.frontData();
        q2.pop();
        ++ret;
      }
      return ret;
    }

    // copy pin history timing to an array, up to a given length.
    // note that this records times between calls to the pin, not between transitions
    // return the number of elements moved
    int toTimestampArray(unsigned long* arr, unsigned int length) const {
      MockEventQueue<T> q2(qOut);  // preserve const by copying

      int ret = 0;
      for (int i = 0; i < length && q2.size(); ++i) {
        arr[i] = q2.frontTime();
        q2.pop();
        ++ret;
      }
      return ret;
    }

    // copy pin history timing to an array, up to a given length.
    // note that this records times between calls to the pin, not between transitions
    // return the number of elements moved
    int toEventArray(typename MockEventQueue<T>::Event* arr, unsigned int length) const {
      MockEventQueue<T> q2(qOut);  // preserve const by copying

      int ret = 0;
      for (int i = 0; i < length && q2.size(); ++i) {
        arr[i] = q2.front();
        q2.pop();
        ++ret;
      }
      return ret;
    }

    // see if the array matches the data of the elements in the queue
    bool hasElements (T const * const arr, unsigned int length) const {
      int i;
      MockEventQueue<T> q2(qOut);  // preserve const by copying
      for (i = 0; i < length && q2.size(); ++i) {
        if (q2.frontData() != arr[i]) return false;
        q2.pop();
      }
      return i == length;
    }

};
