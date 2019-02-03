#include <ArduinoUnitTests.h>
#include <avr/wdt.h>

GodmodeState* state = GODMODE();

unittest(taskWdtEnable_checkTimeout) {
  state->reset();
  assertEqual(0, state->wdt.timeout);

  wdt_enable(WDTO_1S);

  assertTrue(state->wdt.wdt_enable);
  assertEqual(WDTO_1S, state->wdt.timeout);
  assertEqual(1, state->wdt.wdt_enable_count);
}

unittest(taskWdtEnableDisable) {
  state->reset();
  assertEqual(0, state->wdt.wdt_enable_count);

  wdt_enable(WDTO_1S);

  assertTrue(state->wdt.wdt_enable);
  assertEqual(1, state->wdt.wdt_enable_count);

  wdt_disable();

  assertFalse(state->wdt.wdt_enable);
  assertEqual(1, state->wdt.wdt_enable_count);
}

unittest(wdt_reset) {
  state->reset();
  assertEqual(0, state->wdt.wdt_reset_count);

  wdt_reset();

  assertEqual(1, state->wdt.wdt_reset_count);
}

unittest_main()
