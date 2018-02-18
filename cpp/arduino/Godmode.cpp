#include "Godmode.h"
#include "HardwareSerial.h"

GodmodeState godmode = GodmodeState();

GodmodeState* GODMODE() {
  return &godmode;
}

unsigned long millis() {
  GodmodeState* godmode = GODMODE();
  return godmode->micros / 1000;
}

unsigned long micros() {
  GodmodeState* godmode = GODMODE();
  return godmode->micros;
}

void delay(unsigned long millis) {
  GodmodeState* godmode = GODMODE();
  godmode->micros += millis * 1000;
}

void delayMicroseconds(unsigned long micros) {
  GodmodeState* godmode = GODMODE();
  godmode->micros += micros;
}


void randomSeed(unsigned long seed)
{
  GodmodeState* godmode = GODMODE();
  godmode->seed = seed;
}

long random(long vmax)
{
  GodmodeState* godmode = GODMODE();
  godmode->seed += 4294967291;  // it's a prime that fits in 32 bits
  return godmode->seed % vmax;
}

long random(long vmin, long vmax)
{
  return vmin < vmax ? (random(vmax - vmin) + vmin) : vmin;
}

// Serial ports
#if defined(HAVE_HWSERIAL0)
  HardwareSerial Serial(&godmode.serialPort[0].dataIn, &godmode.serialPort[0].dataOut, &godmode.serialPort[0].readDelayMicros);
#endif
#if defined(HAVE_HWSERIAL1)
  HardwareSerial Serial1(&godmode.serialPort[1].dataIn, &godmode.serialPort[1].dataOut, &godmode.serialPort[1].readDelayMicros);
#endif
#if defined(HAVE_HWSERIAL2)
  HardwareSerial Serial2(&godmode.serialPort[2].dataIn, &godmode.serialPort[2].dataOut, &godmode.serialPort[2].readDelayMicros);
#endif
#if defined(HAVE_HWSERIAL3)
  HardwareSerial Serial3(&godmode.serialPort[3].dataIn, &godmode.serialPort[3].dataOut, &godmode.serialPort[3].readDelayMicros);
#endif

template <typename T>
inline std::ostream& operator << ( std::ostream& out, const PinHistory<T>& ph ) {
  out << ph;
  return out;
}
