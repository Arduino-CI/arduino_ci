#include <ArduinoUnitTests.h>
#include <WString.h>
#include <ci/Table.h>

// for testing a work function
// note swapped args because as "isMatch", it's "firstArg, key"
bool isSubstr(String firstArg, String haystack) {
  return strstr(haystack.c_str(), firstArg.c_str());
}

// for testing a work function
int results[5];
void setResult2(int k, int v) {
  results[k] = v;
}
void setResult3(long l, int k, int v) {
  results[k] = v + l;
}


unittest(basic_table)
{
  Table<String, int> t;
  assertTrue(t.empty());

  int data[5] = {11, 22, 33, 44, 55};

  for (int i = 0; i < 5; ++i) {
    assertEqual(i, t.size());
    assertTrue(t.add(String(data[i]), data[i]));
    assertEqual(i + 1, t.size());
  }

  assertTrue(t.has("44"));
  assertFalse(t.has("66"));
  assertEqual(44, t.get("44"));

  assertEqual("33", t.getMatchingKey(String("3"), isSubstr));

  for (int i = 0; i < 5; ++i) {
    assertEqual(5 - i, t.size());
    assertTrue(t.remove(String(data[i])));
    assertFalse(t.has(String(data[i])));
    assertEqual(4 - i, t.size());
  }

}

unittest(iteration_no_arg) {
  Table<int, int> t;
  for (int i = 0; i < 5; ++i) {
    results[i] = 0;
    t.add(i, 11 * (i + 1));
  }

  t.iterate(&setResult2);

  for (int i = 0; i < 5; ++i) assertEqual(11 * (i + 1), results[i]);
}

unittest(iteration_one_arg) {
  Table<int, int> t;
  for (int i = 0; i < 5; ++i) {
    results[i] = 0;
    t.add(i, 11 * (i + 1));
  }

  long offset = 9;
  t.iterate(&setResult3, offset);

  for (int i = 0; i < 5; ++i) assertEqual(11 * (i + 1), results[i] - offset);
}

unittest_main()
