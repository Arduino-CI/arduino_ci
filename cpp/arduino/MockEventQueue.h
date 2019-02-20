#pragma once

template <typename T>
class MockEventQueue {
  public:
    struct Event {
      T data;
      unsigned long micros;

      Event() : data(T()), micros(0) {}
      Event(const T &d, unsigned long const t) : data(d), micros(t) { }
    };

  private:
    struct Node {
      Event event;
      Node* next;

      Node(const Event &e, Node* n) : event(e), next(n) { }
    };

    Node* mFront;
    Node* mBack;
    unsigned long mSize;
    T mNil;
    unsigned long (*mGetMicros)(void);

    void init(unsigned long (*getMicros)(void)) {
      mFront = mBack = nullptr;
      mSize = 0;
      mGetMicros = getMicros;
    }

  public:
    MockEventQueue(unsigned long (*getMicros)(void)): mNil() { init(getMicros); }
    MockEventQueue(): mNil() { init(nullptr); }

    MockEventQueue(const MockEventQueue<T>& q) {
      init(q.mGetMicros);
      for (Node* n = q.mFront; n; n = n->next) push(n->event);
    }

    void setMicrosRetriever(unsigned long (*getMicros)(void)) { mGetMicros = getMicros; }

    inline unsigned long size() const { return mSize; }
    inline bool empty() const { return 0 == mSize; }
    inline Event front() const { return empty() ? Event(mNil, 0) : mFront->event; }
    inline Event back() const { return empty() ?  Event(mNil, 0) : mBack->event; }
    inline T frontData() const { return front().data; }
    inline T backData() const { return back().data; }
    inline unsigned long frontTime() const { return front().micros; }
    inline unsigned long backTime() const { return back().micros; }


    // fully formed event
    bool push(const Event& e) {
      Node *n = new Node(e, nullptr);
      if (n == nullptr) return false;
      mBack = (mFront == nullptr ? mFront : mBack->next) = n;
      return ++mSize;
    }

    // fully specfied event
    bool push(const T& v, unsigned long const time) {
      Event e = {v, time};
      return push(e);
    }

    // event needing timestamp
    bool push(const T& v) {
      unsigned long micros = mGetMicros == nullptr ? 0 : mGetMicros();
      return push(v, micros);
    }

    void pop() {
      if (empty()) return;
      Node* n = mFront;
      mFront = mFront->next;
      delete n;
      if (--mSize == 0) mBack = nullptr;
    }

    void clear() { while (!empty()) pop(); }

    ~MockEventQueue() { clear(); }
};
