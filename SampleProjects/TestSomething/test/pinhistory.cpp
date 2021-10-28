#include <ArduinoUnitTests.h>
#include <Arduino.h>
#include "fibonacciClock.h"

unittest(pin_read_history_int) {
  PinHistory<int> phi;  // pin history int

  const int future[6] = {33, 22, 55, 11, 44, 66};
  assertEqual(0, phi.queueSize());
  phi.fromArray(future, 6);
  for (int i = 0; i < 6; ++i) {
    assertEqual(6 - i, phi.queueSize());
    assertEqual(future[i], phi.retrieve());
    assertEqual(6 - (i + 1), phi.queueSize());
  }

  // assert end of history works
  assertEqual(future[5], phi.retrieve());
}

unittest(pin_read_history_bool_to_ascii) {
  PinHistory<bool> phb;  // pin history bool
  phb.fromAscii("Yo", true);

  // digital history as serial data, big-endian
  bool binaryAscii[16] = {
      0, 1, 0, 1, 1, 0, 0, 1,
      0, 1, 1, 0, 1, 1, 1, 1};

  for (int i = 0; i < 16; ++i) {
    assertEqual(binaryAscii[i], phb.retrieve());
  }

  assertEqual("Yo", phb.toAscii(0, true));
}

unittest(assignment_dumps_queue) {
  PinHistory<bool> phb;  // pin history bool
  assertEqual(0, phb.queueSize());
  assertEqual(0, phb.historySize());
  phb.fromAscii("Yo", true);
  assertEqual(16, phb.queueSize());
  assertEqual(0, phb.historySize());
  phb = false;
  assertEqual(0, phb.queueSize());
  assertEqual(1, phb.historySize());
}

unittest(ascii_to_bool_and_back) {
  PinHistory<bool> phb;
  assertEqual(0, phb.historySize());
  phb.reset(false);
  assertEqual(1, phb.historySize());

  assertEqual(0, phb.queueSize());
  phb.fromAscii("Yo", true);
  assertEqual(16, phb.queueSize());
  assertEqual("Yo", phb.incomingToAscii(0, true));

  phb.reset(false);
  assertEqual(0, phb.queueSize());
  assertEqual(1, phb.historySize());
  phb.outgoingFromAscii("hi", true);
  assertEqual("hi", phb.toAscii(1, true));
}

unittest(write_history) {
  PinHistory<int> phi;  // pin history int
  int expectedA[6] = {0, 11, 22, 33, 44, 55};
  for (int i = 0; i < 6; ++i)
  {
    assertEqual(i, phi.historySize());
    phi = expectedA[i];
    assertEqual(i + 1, phi.historySize());
    assertEqual(0, phi.queueSize());
    assertEqual(phi, expectedA[i]);
  }

  int actualA[6];
  int numMoved = phi.toArray(actualA, 6);
  assertEqual(6, numMoved);
  // assert non-destructive by repeating the operation
  numMoved = phi.toArray(actualA, 6);
  assertEqual(6, numMoved);
  for (int i = 0; i < 6; ++i)
  {
    assertEqual(expectedA[i], actualA[i]);
  }
}

unittest(null_timing) {
  PinHistory<int> phi;  // pin history int
  int expectedA[6] = {0, 11, 22, 33, 44, 55};
  for (int i = 0; i < 6; ++i)
  {
    phi = expectedA[i];
  }

  unsigned long tStamps[6];
  int numMoved = phi.toTimestampArray(tStamps, 6);
  assertEqual(6, numMoved);
  // assert non-destructive by repeating the operation
  numMoved = phi.toTimestampArray(tStamps, 6);
  assertEqual(6, numMoved);
  for (int i = 0; i < 6; ++i)
  {
    assertEqual(0, tStamps[i]);
  }
}

unittest(actual_timing_set_in_constructor) {
  resetFibClock();
  PinHistory<int> phi(fibMicros);  // pin history int
  for (int i = 0; i < 6; ++i)
  {
    phi = 0;
  }

  int expectedT[6] = {1, 1, 2, 3, 5, 8};
  unsigned long tStamps[6];
  int numMoved = phi.toTimestampArray(tStamps, 6);
  assertEqual(6, numMoved);
  for (int i = 0; i < 6; ++i)
  {
    assertEqual(expectedT[i], tStamps[i]);
  }
}

unittest(actual_timing_set_after_constructor) {
  resetFibClock();
  PinHistory<int> phi;  // pin history int
  phi.setMicrosRetriever(fibMicros);
  for (int i = 0; i < 6; ++i)
  {
    phi = 0;
  }

  int expectedT[6] = {1, 1, 2, 3, 5, 8};
  unsigned long tStamps[6];
  int numMoved = phi.toTimestampArray(tStamps, 6);
  assertEqual(6, numMoved);
  for (int i = 0; i < 6; ++i)
  {
    assertEqual(expectedT[i], tStamps[i]);
  }
}

unittest(event_history) {
  resetFibClock();
  PinHistory<int> phi(fibMicros);  // pin history int
  for (int i = 0; i < 6; ++i)
  {
    phi = i;
  }

  int expectedT[6] = {1, 1, 2, 3, 5, 8};
  MockEventQueue<int>::Event event[6];
  int numMoved = phi.toEventArray(event, 6);
  assertEqual(6, numMoved);
  for (int i = 0; i < 6; ++i)
  {
    assertEqual(i, event[i].data);
    assertEqual(expectedT[i], event[i].micros);
  }
}



unittest_main()
