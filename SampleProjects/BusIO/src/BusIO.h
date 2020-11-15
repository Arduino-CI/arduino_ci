#include <Adafruit_SPIDevice.h>
#include <Arduino.h>

class BusIO {
public:
  BusIO() {}
  ~BusIO() {}
  int answer() { return 42; }
}
