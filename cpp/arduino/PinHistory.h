#pragma once
#include <queue>
#include "Forced.h"

// pins with history.
template <typename T>
class PinHistory {
private:
  std::queue<T> q;

  void clear() { while (!q.empty()) q.pop(); }

public:
  PinHistory() {}

  void reset(T val) {
    clear();
    q.push(val);
  }

  unsigned int size() { return q.size(); }

  operator T() const { return q.back(); }

  T &operator=(const T i) {
    q.push(i);
    return q.back();
  }

  // destructively move elements to an array, up to a given length
  // return the number of elements moved
  int toArray(T* arr, unsigned int length) {
    int ret = 0;
    for (int i = 0; i < length && q.size(); ++i) {
      arr[i] = q.front();
      q.pop();
      ++ret;
    }
    return ret;
  }

  // destructively see if the array matches the elements in the queue
  bool hasElements(T* arr, unsigned int length) {
    int i;
    for (i = 0; i < length && q.size(); ++i) {
      if (q.front() != arr[i]) return false;
      q.pop();
    }
    return i == length;
  }

  // destructively convert the pin history to a string as if it was Serial comms
  // start from offset, consider endianness
  String toAscii(unsigned int offset, bool bigEndian) {
    String ret = "";

    while (offset) {
      q.pop();
      --offset;
    }

    if (offset) return ret;

    // 8 chars at a time, form up
    while (q.size() >= 8) {
      unsigned char acc = 0x00;
      for (int i = 0; i < 8; ++i) {
        int shift = bigEndian ? 7 - i : i;
        T val = q.front();
        unsigned char bit = val ? 0x1 : 0x0;
        acc |= (bit << shift);
        q.pop();
      }
      ret.append(String((char)acc));
    }

    return ret;
  }
};

