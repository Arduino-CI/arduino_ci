#pragma once

#include "Assertion.h"
#include <iostream>
using namespace std;

struct Results {
  int passed;
  int failed;
  int skipped;  // TODO: not sure about this
};

struct TestData {
  const char* name;
  int result;
};

class Test
{
  public:
    class ReporterTAP {
      private:
        int mTestCounter;
        int mAssertCounter;

      public:
        ReporterTAP() {}
        ~ReporterTAP() {}

        void onTestRunInit(int numTests) {
          cout << "TAP version 13" << endl;
          cout << 1 << ".." << numTests << endl; // we know how many tests, in advance
          mTestCounter = 0;
        }

        void onTestStart(TestData td) {
          mAssertCounter = 0;
          ++mTestCounter;
          cout << "# Subtest: " << td.name << endl;
        }

        void onTestEnd(TestData td) {
          cout << "    1.." << mAssertCounter << endl;
          if (td.result == RESULT_PASS) {
            cout << "ok " << mTestCounter << " - " << td.name << endl;
          } else {
            cout << "not ok " << mTestCounter << " - " << td.name << endl;
          }
        }

        template <typename A, typename B> void onAssert(
              const char* file,
              int line,
              const char* description,
              bool pass,
              const char* lhsRelevance,
              const char* lhsLabel,
              const A &lhs,
              const char* opLabel,
              const char* rhsRelevance,
              const char* rhsLabel,
              const B &rhs
          ) {
            cout << "    " << (pass ? "" : "not ") << "ok " << ++mAssertCounter << " - ";
            cout << description << " " << lhsLabel << " " << opLabel << " " << rhsLabel << endl;
            if (!pass) {
              cout << "      ---" << endl;
              cout << "      operator: " << opLabel << endl;
              cout << "      " << lhsRelevance << ": " << lhs << endl;
              cout << "      " << rhsRelevance << ": " << rhs << endl;
              cout << "      at:" << endl;
              cout << "        file: " << file << endl;
              cout << "        line: " << line << endl;
              cout << "      ..." << endl;
          }
        }
    };

  private:
    ReporterTAP* mReporter;
    const char* mName;

    // linked list structure for active tests
    static Test* sRoot;
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

  public:
    static const int RESULT_NONE = 0;
    static const int RESULT_PASS = 1;
    static const int RESULT_FAIL = 2;
    static const int RESULT_SKIP = 3;

    const inline char *name() { return mName; }
    const inline int result() { return mResult; }

    Test(const char* _name) : mName(_name) {
      mResult = RESULT_NONE;
      mReporter = 0;
      append();
    }

    inline void fail() { mResult = RESULT_FAIL; }
    inline void skip() { mResult = RESULT_SKIP; }

    static Results run(ReporterTAP* reporter) {
      if (reporter) reporter->onTestRunInit(numTests());
      Results results = {0, 0, 0};

      for (Test *p = sRoot; p; p = p->mNext) {
        TestData td = {p->name(), p->result()};
        p->mReporter = reporter;
        if (reporter) reporter->onTestStart(td);
        p->test();
        if (p->mResult == RESULT_PASS) ++results.passed;
        if (p->mResult == RESULT_FAIL) ++results.failed;
        if (p->mResult == RESULT_SKIP) ++results.skipped;
        if (reporter) reporter->onTestEnd(td);
      }

      return results;
    }

    // TODO: figure out TAP output like
    // https://api.travis-ci.org/v3/job/283745834/log.txt
    // https://testanything.org/tap-specification.html
    // parse input and decide how to report
    static int run_and_report(int argc, char *argv[]) {
      // TODO: pick a reporter based on args
      ReporterTAP rep;
      Results results = run(&rep);
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

    template <typename A, typename B>
    bool assertion(
        const char *file,
        int line,
        const char *description,
        const char *lhsRelevance,
        const char *lhsLabel,
        const A &lhs,

        const char *ops,

        bool (*op)(
            const A &lhs,
            const B &rhs),

        const char *rhsRelevance,
        const char *rhsLabel,
        const B &rhs)
    {
      bool ok = op(lhs, rhs);

      if (mReporter) {
        mReporter->onAssert(file, line, description, ok,
          lhsRelevance, lhsLabel, lhs, ops, rhsRelevance, rhsLabel, rhs);
      }

      if (!ok)
        fail();
      return ok;
    }

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
