#include <ArduinoUnitTests.h>
#include <MockEventQueue.h>
#include "fibonacciClock.h"

unittest(basic_queue_dequeue_and_size)
{
  MockEventQueue<int> q;
  int data[5] = {11, 22, 33, 44, 55};

  assertTrue(q.empty());

  for (int i = 0; i < 5; ++i) {
    assertEqual(i, q.size());
    q.push(data[i]);
    assertEqual(data[i], q.backData());
    assertEqual(0, q.backTime()); // we didn't provide a function, so it should default to 0
    assertEqual(i + 1, q.size());
  }

  for (int i = 0; i < 5; ++i) {
    assertEqual(5 - i, q.size());
    assertEqual(data[i], q.frontData());
    q.pop();
    assertEqual(5 - i - 1, q.size());
  }

  assertTrue(q.empty());
}

unittest(copy_constructor)
{
  MockEventQueue<int> q;
  int data[5] = {11, 22, 33, 44, 55};
  for (int i = 0; i < 5; ++i) q.push(data[i]);

  MockEventQueue<int> q2(q);

  for (int i = 0; i < 5; ++i) {
    assertEqual(5 - i, q2.size());
    assertEqual(data[i], q2.frontData());
    q2.pop();
    assertEqual(5 - i - 1, q2.size());
  }

  for (int i = 0; i < 5; ++i) {
    assertEqual(5 - i, q.size());
    assertEqual(data[i], q.frontData());
    q.pop();
    assertEqual(5 - i - 1, q.size());
  }
}

unittest(boundaries)
{
  MockEventQueue<int> q;
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

unittest(timed_events)
{
  MockEventQueue<int> q;
  int data[7] = {4, 50, 600, 8555, 9000, 9001, 1000000000};
  for (int i = 0; i < 7; ++i) {
    q.push(data[i], data[i]);
    assertEqual(data[i], q.backData());
    assertEqual(data[i], q.backTime());
  }

  for (int i = 0; i < 7; ++i) {
    assertEqual(data[i], q.frontData());
    assertEqual(data[i], q.frontTime());
    q.pop();
  }

}

unittest(my_fib)
{
  resetFibClock();
  assertEqual(1, fibMicros());
  assertEqual(1, fibMicros());
  assertEqual(2, fibMicros());
  assertEqual(3, fibMicros());
  assertEqual(5, fibMicros());
  assertEqual(8, fibMicros());
  assertEqual(13, fibMicros());
  assertEqual(21, fibMicros());
}

unittest(clocked_events)
{
  resetFibClock();
  MockEventQueue<int> q(fibMicros);
  int data[7] = {1, 1, 2, 3, 5, 8, 13}; //eureka
  for (int i = 0; i < 7; ++i) {
    q.push(data[i]);
    assertEqual(data[i], q.backData());
    assertEqual(data[i], q.backTime());
  }

  for (int i = 0; i < 7; ++i) {
    assertEqual(data[i], q.frontData());
    assertEqual(data[i], q.frontTime());
    q.pop();
  }

}

unittest_main()
