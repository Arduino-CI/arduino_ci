#pragma once

template <typename T>
class MockEventQueue {
  private:
    struct Event {
      T data;
      unsigned long micros;
      Event* next;
    };

    Event* mFront;
    Event* mBack;
    unsigned long mSize;
    T mNil;

    void init() {
      mFront = mBack = nullptr;
      mSize = 0;
    }

  public:
    MockEventQueue(): mNil() { init(); }

    MockEventQueue(const MockEventQueue<T>& q) {
      init();
      for (Event* n = q.mFront; n; n = n->next) push(n->data);
    }

    inline unsigned long size() const { return mSize; }
    inline bool empty() const { return 0 == mSize; }
    T front() const { return empty() ? mNil : mFront->data; }
    T back() const { return empty() ? mNil : mBack->data; }

    bool pushEvent(const T& v, unsigned long const time)
    {
      Event *n = new Event;
      if (n == nullptr) return false;
      n->data = v;
      n->micros = time;
      n->next = nullptr;
      mBack = (mFront == nullptr ? mFront : mBack->next) = n;
      return ++mSize;
    }

    bool push(const T& v); // need to use GODMODE here, so defined in Godmode.h

    void pop() {
      if (empty()) return;
      Event* n = mFront;
      mFront = mFront->next;
      delete n;
      if (--mSize) mBack = nullptr;
    }

    void clear() { while (!empty()) pop(); }

    ~MockEventQueue() { clear(); }
};
