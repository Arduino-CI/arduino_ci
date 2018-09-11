#pragma once

// A template-ized lookup table implementation
//
// this is this stupidest table implementation ever but it's
// an MVP for unit testing. O(n).
template <typename K, typename V>
class ArduinoCITable {
  private:
    struct Node {
      K key;
      V val;
      Node *next;
    };

    Node* mStart;
    unsigned long mSize;
    // to alow const reference signatures, pre-allocate nil values
    K mNilK;
    V mNilV;

    void init() {
      mStart = NULL;
      mSize = 0;
    }

  public:
    ArduinoCITable() : mNilK(), mNilV() { init(); }

    ArduinoCITable(const ArduinoCITable& obj) : mNilK(), mNilV() {
      init();
      for (Node* p = obj.mStart; p; p = p->next) {
        add(p->key, p->val);
      }
    }

    // number of things in the table
    inline unsigned long size() const { return mSize; }

    // whether there are no things
    inline bool empty() const { return 0 == mSize; }

    // whether there is a thing stored at the given key
    bool has(K const key) const {
      for (Node* p = mStart; p; p = p->next) {
        if (p->key == key) return true;
      }
      return false;
    }

    // allow find operations on keys
    template <typename T>
    const K& getMatchingKey(T const firstArg, bool (*isMatch)(const T, const K)) const {
        for (Node* p = mStart; p; p = p->next) {
          if (isMatch(firstArg, p->key)) return p->key;
        }
        return mNilK;
    }

    // allow iteration over entire table, with a work function that takes key/value pairs
    void iterate(void (*work)(const K&, const V&)) const {
        for (Node* p = mStart; p; p = p->next) work(p->key, p->val);
    }
    void iterate(void (*work)(K, V)) const {
        for (Node* p = mStart; p; p = p->next) work(p->key, p->val);
    }

    // allow iteration over entire table, with a work function that takes key/value pairs
    // plus an initial argument. this enables member function passing (via workaround)
    template <typename T>
    void iterate(void (*work)(T&, const K&, const V&), T& firstArg) const {
        for (Node* p = mStart; p; p = p->next) work(firstArg, p->key, p->val);
    }

    template <typename T>
    void iterate(void (*work)(T&, K, V), T& firstArg) const {
        for (Node* p = mStart; p; p = p->next) work(firstArg, p->key, p->val);
    }

    template <typename T>
    void iterate(void (*work)(T, K, V), T firstArg) const {
        for (Node* p = mStart; p; p = p->next) work(firstArg, p->key, p->val);
    }

    // return the value for a given key
    const V& get(K const key) const {
      for (Node* p = mStart; p; p = p->next) {
        if (p->key == key) return p->val;
      }
      return mNilV;
    }

    // remove an item by key
    bool remove(K const key) {
      Node *o = NULL;
      for (Node* p = mStart; p; p = p->next) {
        if (p->key == key) {
          (o ? o->next : mStart) = p->next;
          delete p;
          --mSize;
          return true;
        }
        o = p;
      }
      return false;
    }

    // add a key/value pair.  deletes any existing key by that name.
    bool add(K const key, V const val) {
      remove(key);
      Node *n = new Node;
      if (n == NULL) return false;
      n->key = key;
      n->val = val;
      n->next = mStart;
      mStart = n;
      ++mSize;
      return true;
    }

    // remove everything
    void clear() {
      Node* p;
      while (mStart) {
        p = mStart;
        mStart = mStart->next;
        delete p;
      }
      mSize = 0;
    }

    ~ArduinoCITable() { clear(); }
};
