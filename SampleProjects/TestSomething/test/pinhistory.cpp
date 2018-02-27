#include <ArduinoUnitTests.h>
#include <Arduino.h>


unittest(pin_read_history) {
  PinHistory<int> phi;

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

  PinHistory<bool> phb;
  phb.fromAscii("Yo", true);

  // digitial history as serial data, big-endian
  bool binaryAscii[16] = {
      0, 1, 0, 1, 1, 0, 0, 1,
      0, 1, 1, 0, 1, 1, 1, 1};

  for (int i = 0; i < 16; ++i) {
    assertEqual(binaryAscii[i], phb.retrieve());
  }

  assertEqual("Yo", phb.toAscii(0, true));
}

unittest(ascii_stuff) {
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

unittest_main()
