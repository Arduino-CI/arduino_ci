#pragma once

#include <Godmode.h>

#define WDTO_15MS   0
#define WDTO_30MS   1
#define WDTO_60MS   2
#define WDTO_120MS  3
#define WDTO_250MS  4
#define WDTO_500MS  5
#define WDTO_1S     6
#define WDTO_2S     7
#define WDTO_4S     8
#define WDTO_8S     9

void wdt_enable(unsigned char timeout) {
  GodmodeState* godmode = GODMODE();
  godmode->wdt.wdt_enable = true;
  godmode->wdt.timeout = timeout;
  godmode->wdt.wdt_enable_count++;
}

void wdt_disable() {
  GodmodeState* godmode = GODMODE();
  godmode->wdt.wdt_enable = false;
  godmode->wdt.wdt_disable_count++;
}

void wdt_reset() {
  GodmodeState* godmode = GODMODE();
  godmode->wdt.wdt_reset_count++;
}
