#pragma once

#include "Assertion.h"
#include <iostream>
using namespace std;

struct Results {
  int passed;
  int failed;
  int skipped;  // TODO: not sure about this
};

class Test
{


  private:
    const char* mName;

    // linked list structure for active tests
    static Test* sRoot;
    static Test* sCurrent;
    Test* mNext;

    void append() {
      if (!sRoot) return (void)(sRoot = this);
      Test* p;
      for (p = sRoot; p->mNext; p = p->mNext);
      p->mNext = this;
    }

    void excise() {
      for (Test **p = &sRoot; *p != 0; p=&((*p)->mNext)) {
        if (*p == this) return (void)(*p = (*p)->mNext);
       }
    }

    static int numTests() {
      if (!sRoot) return 0;
      int i = 1;
      for (Test* p = sRoot; p->mNext; ++i && (p = p->mNext));
      return i;
    }

    // current test result
    int mResult;
    int mAssertions;

  public:
    static const int RESULT_NONE = 0;
    static const int RESULT_PASS = 1;
    static const int RESULT_FAIL = 2;
    static const int RESULT_SKIP = 3;

    const inline char *name() { return mName; }
    const inline int result() { return mResult; }

    Test(const char *_name) : mName(_name)
    {
      mResult = RESULT_NONE;
      append();
    }

    inline void fail() { mResult = RESULT_FAIL; }
    inline void skip() { mResult = RESULT_SKIP; }


    static int mTestCounter;
    static int mAssertCounter;

    static void onTestRunInit(int numTests) {
      cout << "TAP version 13" << endl;
      cout << 1 << ".." << numTests << endl; // we know how many tests, in advance
      mTestCounter = 0;
    }

    static void onTestStart(Test* test) {
      mAssertCounter = 0;
      ++mTestCounter;
      cout << "# Subtest: " << test->name() << endl;
    }

    static void onTestEnd(Test* test) {
      cout << "    1.." << mAssertCounter << endl;
      if (test->result() == RESULT_PASS) {
        cout << "ok " << mTestCounter << " - " << test->name() << endl;
      } else {
        cout << "not ok " << mTestCounter << " - " << test->name() << endl;
      }
    }

    template <typename A, typename B>
    static void onAssert(
        const char* file,
        int line,
        const char* description,
        bool pass,
        const char* lhsLabel,
        const A &lhs,
        const char* opLabel,
        const char* rhsLabel,
        const B &rhs
    ) {
      cout << "    " << (pass ? "" : "not ") << "ok " << mAssertCounter << " - ";
      cout << description << " " << lhsLabel << " " << opLabel << " " << rhsLabel << endl;
      if (!pass) {
        cout << "      ---" << endl;
        cout << "      operator: " << opLabel << endl;
        cout << "      expected: " << lhsLabel << endl;
        cout << "      actual: " << endl;
        cout << "      at:" << endl;
        cout << "        file: " << file << endl;
        cout << "        line: " << line << endl;
        cout << "      ..." << endl;
      }
    }

    static Results run() {
      onTestRunInit(numTests());
      Results results = {0, 0, 0};

      for (Test *p = sRoot; p; p = p->mNext) {
        sCurrent = p;
        onTestStart(p);
        p->test();
        if (p->mResult == RESULT_PASS) ++results.passed;
        if (p->mResult == RESULT_FAIL) ++results.failed;
        if (p->mResult == RESULT_SKIP) ++results.skipped;
        onTestEnd(p);
      }

      return results;
    }

    // TODO: figure out TAP output like
    // https://api.travis-ci.org/v3/job/283745834/log.txt
    // https://testanything.org/tap-specification.html
    // parse input and deicde how to report
    static int run_and_report(int argc, char *argv[]) {
      Results results = run();
      return results.failed + results.skipped;
    }

    void test() {
      mResult = RESULT_PASS; // not None, and not fail unless we hear otherwise
      task();
    }

    virtual void task() = 0;

    virtual ~Test() {
      excise();
    }

    // FYI
    // #define assertOp(arg1,op,op_name,arg2) do { if (!assertion<typeof(arg1),typeof(arg2)>(__FILE__,__LINE__,#arg1,(arg1),op_name,op,#arg2,(arg2))) return; } while (0)
    // #define assertEqual(arg1,arg2)       assertOp(arg1,compareEqual,"==",arg2)

    template <typename A, typename B>
    bool assertion(
        const char *file,
        int line,
        const char *description,
        const char *lhss,
        const A &lhs,

        const char *ops,

        bool (*op)(
            const A &lhs,
            const B &rhs),

        const char *rhss,
        const B &rhs)
    {
      ++mAssertCounter;
      bool ok = op(lhs, rhs);
      onAssert(file, line, description, ok, lhss, lhs, ops, rhss, rhs);

      if (!ok)
        sCurrent->fail();
      return ok;
  }

  public:
    class Reporter {
      public:
        Reporter() {}
        virtual ~Reporter() {}

        void onInit(int numTests) {}
        void onTest(Test* test) {}
        void onTestEnd(Test* test) {}
        void onAssert() {}
        void onFinish(Results results) {}
    };

    class ReporterTAP : Reporter {
      private:

      public:
        ReporterTAP() : Reporter() {}
        ~ReporterTAP() {}
    };

};

/**
 * Extend the class into a struct.
 * The implementation of task() will follow the macro
 *
 */
#define unittest(name)             \
  struct test_##name : Test        \
  {                                \
    test_##name() : Test(#name){}; \
    void task();                   \
  } test_##name##_instance;        \
  void test_##name ::task()
