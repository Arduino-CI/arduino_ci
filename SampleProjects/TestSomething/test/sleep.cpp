#include <ArduinoUnitTests.h>
#include <avr/sleep.h>

GodmodeState* state = GODMODE();

unittest(sleep_enable) {
  state->reset();
  assertFalse(state->sleep.sleep_enable);
  assertEqual(0, state->sleep.sleep_enable_count);

  sleep_enable();

  assertTrue(state->sleep.sleep_enable);
  assertEqual(1, state->sleep.sleep_enable_count);
}

unittest(sleep_disable) {
  state->reset();
  assertEqual(0, state->sleep.sleep_disable_count);

  sleep_disable();

  assertFalse(state->sleep.sleep_enable);
  assertEqual(1, state->sleep.sleep_disable_count);
}

unittest(set_sleep_mode) {
  state->reset();
  assertEqual(0, state->sleep.sleep_mode);

  set_sleep_mode(SLEEP_MODE_PWR_DOWN);

  assertEqual(SLEEP_MODE_PWR_DOWN, state->sleep.sleep_mode);
}

unittest(sleep_bod_disable) {
  state->reset();
  assertEqual(0, state->sleep.sleep_bod_disable_count);

  sleep_bod_disable();

  assertEqual(1, state->sleep.sleep_bod_disable_count);
}

unittest(sleep_cpu) {
  state->reset();
  assertEqual(0, state->sleep.sleep_cpu_count);

  sleep_cpu();

  assertEqual(1, state->sleep.sleep_cpu_count);
}

unittest(sleep_mode) {
  state->reset();
  assertEqual(0, state->sleep.sleep_mode_count);

  sleep_mode();

  assertEqual(1, state->sleep.sleep_mode_count);
  assertEqual(1, state->sleep.sleep_enable_count);
  assertEqual(1, state->sleep.sleep_disable_count);
}

unittest_main()
