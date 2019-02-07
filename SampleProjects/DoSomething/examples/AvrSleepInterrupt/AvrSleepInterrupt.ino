#include <avr/sleep.h>

#define BUTTON_INT_PIN 2

void setup() {
  Serial.begin(115200);
  Serial.println("start");
  delay(200);
  pinMode(BUTTON_INT_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(BUTTON_INT_PIN), isrButtonTrigger, FALLING);
}

void loop() {
  // sleep unti an interrupt occurs
  sleep_enable(); // enables the sleep bit, a safety pin
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);
  sleep_cpu(); // here the device is actually put to sleep
  sleep_disable(); // disables the sleep bit, a safety pin

  Serial.println("interrupt");
  delay(200);
}

void isrButtonTrigger() {
  // nothing to do, wakes up the CPU
}

