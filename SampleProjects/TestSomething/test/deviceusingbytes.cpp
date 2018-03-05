#include <Arduino.h>
#include <ArduinoUnitTests.h>
#include <SoftwareSerial.h>
#include <ci/DeviceUsingBytes.h>

// DeviceUsingBytes extends DataStreamObserver,
// so we will be able to attach this class to an
// ObservableDataStream object, of which the pin
// history (soft-serial) and HardwareSerial
// objects are.
class FakeHayesModem : public DeviceUsingBytes {
  public:
    String mLast;
    bool mMatchedInput;

    FakeHayesModem() : DeviceUsingBytes() {
      mLast = "";
      mMatchedInput = false;
      addResponseLine("AT", "OK");
      addResponseLine("ATV1", "NO CARRIER");
    }

    virtual ~FakeHayesModem() {}

    virtual void onMatchInput(String output) {
      mLast = output;
      mMatchedInput = true;
    }
};

unittest(modem_hardware)
{
  GodmodeState* state = GODMODE();
  state->reset();

  String cmd = "AT\n";

  FakeHayesModem m;
  m.attach(&Serial);
  assertEqual(0, Serial.available());
  assertFalse(m.mMatchedInput);
  assertEqual("", m.mMessage);

  for (int i = 0; i < cmd.length(); ++i) {
    assertEqual(i, m.mMessage.length());  // before we write, length should equal i
    Serial.write(cmd[i]);
  }
  assertEqual(0, m.mMessage.length());  // should have matched and reset

  assertEqual("", state->serialPort[0].dataIn);
  assertEqual("AT\n", state->serialPort[0].dataOut);

  assureTrue(m.mMatchedInput);
  //assertEqual(3, Serial.available());
  assertEqual("OK\n", m.mLast);
}

unittest(modem_software)
{
  GodmodeState* state = GODMODE();
  state->reset();

  bool bigEndian = false;
  bool flipLogic = false;
  SoftwareSerial ss(1, 2, flipLogic);
  ss.listen();

  String cmd = "AT\n";

  FakeHayesModem m;
  m.attach(&state->digitalPin[2]);
  assertEqual(0, ss.available());
  assertFalse(m.mMatchedInput);
  assertEqual("", m.mMessage);

  for (int i = 0; i < cmd.length(); ++i) {
    assertEqual(i, m.mMessage.length());  // before we write, length should equal i
    assertEqual(cmd.substr(0, i), state->digitalPin[2].toAscii(1, bigEndian));
    assertEqual(cmd.substr(0, i), m.mMessage);
    ss.write(cmd[i]);
  }
  assertEqual(0, m.mMessage.length());  // should have matched and reset

  assertEqual("", state->digitalPin[1].incomingToAscii(1, bigEndian));
  assertEqual("AT\n", state->digitalPin[2].toAscii(1, bigEndian));


  assureTrue(m.mMatchedInput);
  //assertEqual(3, Serial.available());
  assertEqual("OK\n", m.mLast);
}

unittest_main()
