#include <ArduinoUnitTests.h>
#include <ci/Queue.h>

unittest(basic_queue_dequeue_and_size)
{
  ArduinoCIQueue<int> q;
  int data[5] = {11, 22, 33, 44, 55};

  assertTrue(q.empty());

  for (int i = 0; i < 5; ++i) {
    assertEqual(i, q.size());
    q.push(data[i]);
    assertEqual(data[i], q.back());
    assertEqual(i + 1, q.size());
  }

  for (int i = 0; i < 5; ++i) {
    assertEqual(5 - i, q.size());
    assertEqual(data[i], q.front());
    q.pop();
    assertEqual(5 - i - 1, q.size());
  }

  assertTrue(q.empty());
}

unittest(copy_constructor)
{
  ArduinoCIQueue<int> q;
  int data[5] = {11, 22, 33, 44, 55};
  for (int i = 0; i < 5; ++i) q.push(data[i]);

  ArduinoCIQueue<int> q2(q);

  for (int i = 0; i < 5; ++i) {
    assertEqual(5 - i, q2.size());
    assertEqual(data[i], q2.front());
    q2.pop();
    assertEqual(5 - i - 1, q2.size());
  }

  for (int i = 0; i < 5; ++i) {
    assertEqual(5 - i, q.size());
    assertEqual(data[i], q.front());
    q.pop();
    assertEqual(5 - i - 1, q.size());
  }
}

unittest(boundaries)
{
  ArduinoCIQueue<int> q;
  int data[2] = {11, 22};
  for (int i = 0; i < 2; ++i) q.push(data[i]);

  assertEqual(2, q.size());
  q.pop();
  assertEqual(1, q.size());
  q.pop();
  assertEqual(0, q.size());
  q.pop();
  assertEqual(0, q.size());

}

unittest_main()
