#pragma once

template <typename T>
class queue {
  private:
    struct Node {
      T data;
      Node* next;
    };

    Node* mFront;
    Node* mBack;
    unsigned long mSize;
    T mNil;

    void init() {
      mFront = mBack = NULL;
      mSize = 0;
    }

  public:
    queue() { init(); }

    queue(const queue<T>& q) {
      init();
      for (Node* n = q.mFront; n; n = n->next) push(n->data);
    }

    inline unsigned long size() const { return mSize; }

    inline bool empty() const { return 0 == mSize; }

    const T& front() const { return empty() ? mNil : mFront->data; }

    const T& back() const { return empty() ? mNil : mBack->data; }

    bool push(const T& v)
    {
      Node *n = new Node;
      if (n == NULL) return false;

      n->data = v;
      n->next = NULL;

      if (mFront == NULL)
      {
        mFront = mBack = n;
      } else {
        mBack->next = n;
        mBack = n;
      }

      ++mSize;
      return true;
    }

    void pop() {
      if (empty()) return;
      if (mFront == mBack) {
        mFront = mBack = NULL;
      } else {
        Node* n = mFront;
        mFront = mFront->next;
        delete n;
      }

      --mSize;
    }

    void clear() { while (!empty()) pop(); }

    ~queue() { clear(); }
};
