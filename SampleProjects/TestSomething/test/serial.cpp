#include <ArduinoUnitTests.h>
#include <Arduino.h>

#if defined(HAVE_HWSERIAL0)
  #define HAVE_SERIAL true
#else
  #define HAVE_SERIAL false
#endif

bool have_serial_ports = HAVE_SERIAL;

unittest(serial_ports)
{
  assertTrue(have_serial_ports);
}

#ifdef HAVE_HWSERIAL0

  unittest(reading_writing_serial)
  {
    GodmodeState* state = GODMODE();
    state->serialPort[0].dataIn = "";
    state->serialPort[0].dataOut = "";
    assertEqual(-1, Serial.peek());
    assertEqual("", state->serialPort[0].dataIn);
    assertEqual("", state->serialPort[0].dataOut);

    state->serialPort[0].dataIn = "a";
    assertEqual('a', Serial.peek());
    assertEqual("a", state->serialPort[0].dataIn);
    assertEqual("", state->serialPort[0].dataOut);

    assertEqual('a', Serial.read());
    assertEqual("", state->serialPort[0].dataIn);
    assertEqual("", state->serialPort[0].dataOut);

    Serial.write('b');
    assertEqual("", state->serialPort[0].dataIn);
    assertEqual("b", state->serialPort[0].dataOut);

    Serial.print("cdefg");
    assertEqual("", state->serialPort[0].dataIn);
    assertEqual("bcdefg", state->serialPort[0].dataOut);
  }

  unittest(all_serial_writes)
  {
    GodmodeState* state = GODMODE();
    state->serialPort[0].dataIn = "";
    state->serialPort[0].dataOut = "";

    char str[4] = "xyz";
    Serial.write(reinterpret_cast<const uint8_t *>(str ), 3);
    Serial.print((int)1);
    Serial.print((long)2);
    Serial.print((double)3.4);
    Serial.print((char)'a');
    Serial.print("b");
    assertEqual("xyz123.4000000000ab", state->serialPort[0].dataOut);
  }

#endif

unittest_main()
