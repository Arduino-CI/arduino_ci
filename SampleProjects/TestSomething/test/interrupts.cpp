#include <ArduinoUnitTests.h>
#include <Arduino.h>

void myInterruptHandler() {
}

unittest(interrupts)
{
  // these are meaningless for testing; just call the routine directly.
  // make sure our mocks work though
  attachInterrupt(2, myInterruptHandler, CHANGE);
  detachInterrupt(2);
}

unittest(interrupt_attachment) {
  GodmodeState *state = GODMODE();
  state->reset();
  assertFalse(state->interrupt[0].attached);
  attachInterrupt(0, (void (*)(void))0, 3);
  assertTrue(state->interrupt[0].attached);
  assertEqual(state->interrupt[0].mode, 3);
  detachInterrupt(0);
  assertFalse(state->interrupt[0].attached);
}

// Just check if declaration compiles.
// WDT_vect defines the interrupt of the watchdog timer
// if configured accordinly.
// See avr/interrupt.h
ISR (WDT_vect) {
}

unittest_main()
