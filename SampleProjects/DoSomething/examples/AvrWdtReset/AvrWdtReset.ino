#include <avr/wdt.h>

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  wdt_enable(WDTO_4S);
  // First timeout executes interrupt, second does reset.
  // So first LED 4s off
  // then LED 4s on
  // then reset CPU and start again
  WDTCSR |= (1 << WDIE);
}

void loop() {
  // the program is alive...for now.
  wdt_reset();

  while (1)
    ; // do nothing. the program will lockup here.

  // Can not get here
}

ISR (WDT_vect) {
  // WDIE & WDIF is cleared in hardware upon entering this ISR
  digitalWrite(LED_BUILTIN, HIGH);
}

