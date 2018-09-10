#include <ArduinoUnitTests.h>
#include <Arduino.h>

unittest(millis_micros_and_delay)
{
  GodmodeState* state = GODMODE();
  state->reset();
  assertEqual(0, millis());
  assertEqual(0, micros());
  delay(3);
  assertEqual(3, millis());
  assertEqual(3000, micros());
  delayMicroseconds(11000);
  assertEqual(14, millis());
  assertEqual(14000, micros());
}

unittest(random)
{
  GodmodeState* state = GODMODE();
  state->reset();
  randomSeed(1);
  assertEqual(state->seed, 1);

  unsigned long x;
  x = random(4294967293);
  assertEqual(4294967292, x);
  assertEqual(state->seed, 4294967292);
  x = random(50, 100);
  assertEqual(87, x);
  assertEqual(state->seed, 4294967287);
  x = random(100);
  assertEqual(82, x);
  assertEqual(state->seed, 4294967282);
}

void myInterruptHandler() {
}

unittest(interrupts)
{
  // these are meaningless for testing; just call the routine directly.
  // make sure our mocks work though
  attachInterrupt(2, myInterruptHandler, CHANGE);
  detachInterrupt(2);
}

unittest(pins)
{
  GodmodeState* state = GODMODE();
  state->reset();
  pinMode(1, OUTPUT);  // this is a no-op in unit tests.  it's just here to prove compilation
  digitalWrite(1, HIGH);
  assertEqual(HIGH, state->digitalPin[1]);
  assertEqual(HIGH, digitalRead(1));
  digitalWrite(1, LOW);
  assertEqual(LOW, state->digitalPin[1]);
  assertEqual(LOW, digitalRead(1));

  pinMode(1, INPUT);
  state->digitalPin[1] = HIGH;
  assertEqual(HIGH, digitalRead(1));
  state->digitalPin[1] = LOW;
  assertEqual(LOW, digitalRead(1));

  analogWrite(1, 37);
  assertEqual(37, state->analogPin[1]);
  analogWrite(1, 22);
  assertEqual(22, state->analogPin[1]);

  state->analogPin[1] = 99;
  assertEqual(99, analogRead(1));
  state->analogPin[1] = 56;
  assertEqual(56, analogRead(1));
}

unittest(pin_read_history)
{
  GodmodeState* state = GODMODE();
  state->reset();

  int future[6] = {33, 22, 55, 11, 44, 66};
  state->analogPin[1].fromArray(future, 6);
  for (int i = 0; i < 6; ++i)
  {
    assertEqual(future[i], analogRead(1));
  }

  // assert end of history works
  assertEqual(future[5], analogRead(1));

  state->digitalPin[1].fromAscii("Yo", true);
  // digitial history as serial data, big-endian
  bool binaryAscii[16] = {
    0, 1, 0, 1, 1, 0, 0, 1,
    0, 1, 1, 0, 1, 1, 1, 1
  };

  for (int i = 0; i < 16; ++i) {
    assertEqual(binaryAscii[i], digitalRead(1));
  }
}

unittest(pin_write_history)
{
  GodmodeState *state = GODMODE();
  state->reset();
  int numMoved;

  // history for digital pin
  digitalWrite(1, HIGH);
  digitalWrite(1, LOW);
  digitalWrite(1, LOW);
  digitalWrite(1, HIGH);
  digitalWrite(1, HIGH);

  assertEqual(6, state->digitalPin[1].historySize());
  bool expectedD[6] = {LOW, HIGH, LOW, LOW, HIGH, HIGH};
  bool actualD[6];
  numMoved = state->digitalPin[1].toArray(actualD, 6);
  assertEqual(6, numMoved);
  // assert non-destructive
  numMoved = state->digitalPin[1].toArray(actualD, 6);
  assertEqual(6, numMoved);

  for (int i = 0; i < 6; ++i)
  {
    assertEqual(expectedD[i], actualD[i]);
  }

  // history for analog pin
  analogWrite(1, 11);
  analogWrite(1, 22);
  analogWrite(1, 33);
  analogWrite(1, 44);
  analogWrite(1, 55);

  assertEqual(6, state->analogPin[1].historySize());
  int expectedA[6] = {0, 11, 22, 33, 44, 55};
  int actualA[6];
  numMoved = state->analogPin[1].toArray(actualA, 6);
  assertEqual(6, numMoved);
  // assert non-destructive
  numMoved = state->analogPin[1].toArray(actualA, 6);
  assertEqual(6, numMoved);

  for (int i = 0; i < 6; ++i)
  {
    assertEqual(expectedA[i], actualA[i]);
  }

  // digitial history as serial data, big-endian
  bool binaryAscii[24] = {
      0, 1, 0, 1, 1, 0, 0, 1,
      0, 1, 1, 0, 0, 1, 0, 1,
      0, 1, 1, 1, 0, 0, 1, 1};

  for (int i = 0; i < 24; digitalWrite(2, binaryAscii[i++]))
    ;

  assertEqual("Yes", state->digitalPin[2].toAscii(1, true));

  // digitial history as serial data, little-endian
  bool binaryAscii2[16] = {
      0, 1, 1, 1, 0, 0, 1, 0,
      1, 1, 1, 1, 0, 1, 1, 0};

  for (int i = 0; i < 16; digitalWrite(3, binaryAscii2[i++]))
    ;

  assertEqual("No", state->digitalPin[3].toAscii(1, false));

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

unittest(spi) {
  GodmodeState *state = GODMODE();
  state->reset();
  assertEqual("", state->spi.dataIn);
  assertEqual("", state->spi.dataOut);

  // 8-bit
  state->reset();
  state->spi.dataIn = "LMNO";
  uint8_t out8 = SPI.transfer('a');
  assertEqual("a", state->spi.dataOut);
  assertEqual('L', out8);
  assertEqual("MNO", state->spi.dataIn);

  // 16-bit
  union { uint16_t val; struct { char lsb; char msb; }; } in16, out16;
  state->reset();
  state->spi.dataIn = "LMNO";
  in16.lsb = 'a';
  in16.msb = 'b';
  out16.val = SPI.transfer16(in16.val);
  assertEqual("NO", state->spi.dataIn);
  assertEqual('L', out16.lsb);
  assertEqual('M', out16.msb);
  assertEqual("ab", state->spi.dataOut);

  // buffer
  state->reset();
  state->spi.dataIn = "LMNOP";
  char inBuf[6] = "abcde";
  SPI.transfer(inBuf, 4);

  assertEqual("abcd", state->spi.dataOut);
  assertEqual("LMNOe", String(inBuf));
}



#ifdef HAVE_HWSERIAL0

  void smartLightswitchSerialHandler(int pin) {
    if (Serial.available() > 0) {
      int incomingByte = Serial.read();
      int val = incomingByte == '0' ? LOW : HIGH;
      Serial.print("Ack ");
      digitalWrite(pin, val);
      Serial.print(String(pin));
      Serial.print(" ");
      Serial.print((char)incomingByte);
    }
  }

  unittest(does_nothing_if_no_data)
  {
      GodmodeState* state = GODMODE();
      int myPin = 3;
      state->serialPort[0].dataIn = "";
      state->serialPort[0].dataOut = "";
      state->digitalPin[myPin] = LOW;
      smartLightswitchSerialHandler(myPin);
      assertEqual(LOW, state->digitalPin[myPin]);
      assertEqual("", state->serialPort[0].dataOut);
  }

  unittest(keeps_pin_low_and_acks)
  {
      GodmodeState* state = GODMODE();
      int myPin = 3;
      state->serialPort[0].dataIn = "0";
      state->serialPort[0].dataOut = "";
      state->digitalPin[myPin] = LOW;
      smartLightswitchSerialHandler(myPin);
      assertEqual(LOW, state->digitalPin[myPin]);
      assertEqual("", state->serialPort[0].dataIn);
      assertEqual("Ack 3 0", state->serialPort[0].dataOut);
  }

  unittest(flips_pin_high_and_acks)
  {
      GodmodeState* state = GODMODE();
      int myPin = 3;
      state->serialPort[0].dataIn = "1";
      state->serialPort[0].dataOut = "";
      state->digitalPin[myPin] = LOW;
      smartLightswitchSerialHandler(myPin);
      assertEqual(HIGH, state->digitalPin[myPin]);
      assertEqual("", state->serialPort[0].dataIn);
      assertEqual("Ack 3 1", state->serialPort[0].dataOut);
  }

  unittest(two_flips)
  {
      GodmodeState* state = GODMODE();
      int myPin = 3;
      state->serialPort[0].dataIn = "10junk";
      state->serialPort[0].dataOut = "";
      state->digitalPin[myPin] = LOW;
      smartLightswitchSerialHandler(myPin);
      assertEqual(HIGH, state->digitalPin[myPin]);
      assertEqual("0junk", state->serialPort[0].dataIn);
      assertEqual("Ack 3 1", state->serialPort[0].dataOut);
      state->serialPort[0].dataOut = "";
      smartLightswitchSerialHandler(myPin);
      assertEqual(LOW, state->digitalPin[myPin]);
      assertEqual("junk", state->serialPort[0].dataIn);
      assertEqual("Ack 3 0", state->serialPort[0].dataOut);
  }
#endif



unittest_main()
