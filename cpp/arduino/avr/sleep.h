/*
   This header file defines the functionality to put AVR CPUs to sleep mode.
   For details see
   https://www.nongnu.org/avr-libc/user-manual/group__avr__sleep.html
*/
#pragma once

#include <Godmode.h>

void sleep_enable() {
  GodmodeState* godmode = GODMODE();
  godmode->sleep.sleep_enable = true;
  godmode->sleep.sleep_enable_count++;
}

void sleep_disable() {
  GodmodeState* godmode = GODMODE();
  godmode->sleep.sleep_enable = false;
  godmode->sleep.sleep_disable_count++;
}

void set_sleep_mode(unsigned char mode) {
  GodmodeState* godmode = GODMODE();
  godmode->sleep.sleep_mode = mode;
}

void sleep_bod_disable() {
  GodmodeState* godmode = GODMODE();
  godmode->sleep.sleep_bod_disable_count++;
}

void sleep_cpu() {
  GodmodeState* godmode = GODMODE();
  godmode->sleep.sleep_cpu_count++;
}

void sleep_mode() {
  GodmodeState* godmode = GODMODE();
  sleep_enable();
  godmode->sleep.sleep_mode_count++;
  sleep_disable();
}
