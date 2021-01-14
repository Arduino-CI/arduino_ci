# Build / Test Behavior of Arduino CI

All tests are run via the same command: `bundle exec arduino_ci.rb`.

This script is responsible for detecting and runing all unit tests, on every combination of Arduino platform and C++ compiler.  This is followed by attempting to detect and build every example on every "default" Arduino platform.

As a prerequisite, all Arduino "default" platforms are installed if they are not already available.

These defaults are specified in [misc/default.yml](misc/default.yml).  You are free to define new platforms and different compilers as you see fit, using your own project-specific overrides.


## Directly Overriding Build Behavior (short term use)

When testing locally, it's often advantageous to limit the number of tests that are performed to only those tests that relate to the work you're doing; you'll get a faster turnaround time in seeing the results.  For a full listing, see `bundle exec arduino_ci.rb --help`.


### `--skip-unittests` option

This completely skips the unit testing portion of the CI script.


### `--skip-compilation` option (deprecated)

This completely skips the compilation tests (of library examples) portion of the CI script.  It does not skip the compilation of unit tests.


### `--skip-examples-compilation` option

This completely skips the compilation tests (of library examples) portion of the CI script.  It does not skip the compilation of unit tests.


### `--skip-library-properties` option

This completely skips validation of entries in `library.properties`.


### `--testfile-select` option

This allows a file (or glob) pattern to be executed in your tests directory, creating a whitelist of files to test.  E.g. `--testfile-select=test_animal_*.cpp` would match `test_animal_cat.cpp` and `test_animal_dog.cpp` (testing only those) and not `test_plant_rose.cpp`.


### `--testfile-reject` option

This allows a file (or glob) pattern to be executed in your tests directory, creating a blacklist of files to skip.  E.g. `--testfile-reject=test_animal_*.cpp` would match `test_animal_cat.cpp` and `test_animal_dog.cpp` (skipping those) and test only `test_plant_rose.cpp`, `test_plant_daisy.cpp`, etc.


### `CUSTOM_INIT_SCRIPT` environment variable

If set, testing will execute (using `/bin/sh`) the script referred to by this variable -- relative to the current working directory (i.e. the root directory of the library).  The script will _run_ in the Arduino Libraries directory (changing to the Libraries directory, running the script, and returning to the individual library root afterward).  This enables use cases like the GitHub action to install custom library versions (i.e. a version of a library that is different than what the library manager would automatically install by name) prior to CI test runs.


### `USE_SUBDIR` environment variable

If set, testing will be conducted in this subdirectory (relative to the working directory).  This is for monorepos or other layouts where the library directory and project root directory are different.


### `EXPECT_UNITTESTS` environment variable

If set, testing will fail if no unit test files are detected (or if the directory does not exist).  This is to avoid communicating a passing status in cases where a commit may have accidentally moved or deleted the test files.


### `EXPECT_EXAMPLES` environment variable

If set, testing will fail if no example sketches are detected.  This is to avoid communicating a passing status in cases where a commit may have accidentally moved or deleted the examples.


## Indirectly Overriding Build Behavior (medium term use), and Advanced Options

For build behavior that you'd like to persist across commits (e.g. defining the set of platforms to test against, disabling a test that you expect to re-enable at some future point), a special configuration file called `.arduino-ci.yml` can be used.  There are 3 places you can put them:

1. the root of your library
2. the `test/` directory
3. a subdirectory of `examples/`

`.arduino-ci.yml` files in `test/` or an example sketch take section-by-section precedence over a file in the library root, which takes precedence over the default configuration.


### Defining New Arduino Platforms

Arduino boards are typically named in the form `manufacturer:family:model`.  These definitions are not arbitrary -- they are defined in an Arduino _package_.  For all but the built-in packages, you will need a package URL.  Here is Adafruit's: https://adafruit.github.io/arduino-board-index/package_adafruit_index.json

Here is how you would declare a package that includes the `potato:salad` set of platforms (aka "board family") in your `.arduino-ci.yml`:

```yaml
packages:
  potato:salad:
    url: https://potato.github.io/arduino-board-index/package_salad_index.json
```

To define a platform called `bogo` that uses a board called `potato:salad:bogo` (based on the `potato:salad` family), set it up in the `plaforms:` section.  Note that this will override any default configuration of `bogo` if it had existed in `arduino_ci`'s `misc/default.yml` file.  If this board defines particular features in the compiler, you can set those here.

> Note that the platform names are arbitrary -- just keys in this yaml file and in the [`default.yml`](https://github.com/Arduino-CI/arduino_ci/blob/master/misc/default.yml) file included in this gem.  That said, they are also case sensitive; defining the `bogo` platform will not let you refer to it as `Bogo` nor `BOGO`.

```yaml
platforms:
  # our custom definition of the "bogo" platform
  bogo:
    board: potato:salad:bogo
    package: potato:salad
    gcc:
      features:
        - omit-frame-pointer  # becomes -fomit-frame-pointer flag
      defines:
        - HAVE_THING          # becomes -DHAVE_THING flag
      warnings:
        - no-implicit         # becomes -Wno-implicit flag
      flags:
        - -foobar             # becomes -foobar flag

  # overriding the `zero` platform, to remove it completely
  zero: ~

  # redefine the existing esp8266
  esp8266:
    board: esp8266:esp8266:booo
    package: esp8266:esp8266
    gcc:
      features:
      defines:
      warnings:
      flags:
```

### Control How Examples Are Compiled

Put a file `.arduino-ci.yml` in each example directory where you require a different configuration than default.
The `compile:` section controls the platforms on which the compilation will be attempted, as well as any external libraries that must be installed and included.  This works by _overriding_ portions of the default configuration.

> Note that the platform names _must_ match (case-sensitive) the platform names in the underlying [`default.yml`](https://github.com/Arduino-CI/arduino_ci/blob/master/misc/default.yml), or else match platforms that you have defined yourself in your `.arduino-ci.yml` override.

```yaml
compile:
  # Choosing to run compilation tests on 2 different Arduino platforms
  platforms:
    - esp8266
    - bogo

  # Declaring Dependent Arduino Libraries (to be installed via the Arduino Library Manager)
  libraries:
    - "Adafruit FONA Library"
```


### Control How Unit Tests Are Compiled and Run

For your unit tests, in addition to setting specific libraries and platforms, you may filter the list of test files that are compiled and tested and choose additional compilers on which to run your tests.

Filtering your unit tests may help speed up targeted testing locally, but it is intended primarily as a means to temporarily disable tests between individual commits.

Furthermore, you can filter the files that will be included in the compilation step by specifying `exclude_dirs`. All cpp and header files in those directories will not be included in the compilation step, before the unittests are run.

```yaml
unittest:

  # Exclude these directories from compilation
  exclude_dirs:
    - someDirectory
    - someOtherDirectory

  # Perform unit tests with these compilers (these are the binaries that will be called via the shell)
  compilers:
    - g++      # default
    - g++-4.9
    - g++-7

  # Filter the list of test files in some way
  testfiles:
    # files matching this glob (executed inside the `test/` directory) will be whitelisted for testing
    select:
      - "*-*.*"

    # files matching this glob will be blacklisted from testing
    reject:
      - "sam-squamsh.*"

  # These dependent libraries will be installed
  libraries:
    - "abc123"
    - "def456"

  # each of these platforms will be used when compiling the unit tests
  platforms:
    - bogo
```

The expected number of tests will be the product of:

* Number of compilers defined
* Number of platforms defined
* Number of matching test files


## Writing Unit tests in `test/`

All `.cpp` files in the `test/` directory of your Arduino library are assumed to contain unit tests.  Each and every one will be compiled and executed on its own.


### Most Basic Unit Test

The most basic unit test file is as follows:

```C++
#include <ArduinoUnitTests.h>
#include "../do-something.h"

unittest(your_test_name)
{
  assertEqual(4, doSomething());
}

unittest_main()
```

This test defines one `unittest` (a macro provided by `ArduinoUnitTests.h`), called `your_test_name`, which makes some assertions on the target library.  The `unittest_main()` is a macro for the `int main()` boilerplate required for unit testing.

### Assertions

The following assertion functions are available in unit tests.

```c++
assertEqual(expected, actual);               // a == b
assertNotEqual(unwanted, actual);            // a != b
assertComparativeEquivalent(expected, actual);    // abs(a - b) == 0 or (!(a > b) && !(a < b))
assertComparativeNotEquivalent(unwanted, actual); // abs(a - b) > 0  or ((a > b) || (a < b))
assertLess(upperBound, actual);              // a < b
assertMore(lowerBound, actual);              // a > b
assertLessOrEqual(upperBound, actual);       // a <= b
assertMoreOrEqual(lowerBound, actual);       // a >= b
assertTrue(actual);
assertFalse(actual);
assertNull(actual);

// special cases for floats
assertEqualFloat(expected, actual, epsilon);    // fabs(a - b) <= epsilon
assertNotEqualFloat(unwanted, actual, epsilon); // fabs(a - b) >= epsilon
assertInfinity(actual);                         // isinf(a)
assertNotInfinity(actual);                      // !isinf(a)
assertNAN(arg);                                 // isnan(a)
assertNotNAN(arg);                              // !isnan(a)
```

These functions will report the result of the test to the console, and the testing will continue if they fail.

**If a test failure indicates that all subsequent tests will also fail** then it might be wiser to use _assure_ instead of _assert_ (e.g. `assureEqual(1, myVal)`).  All of the above "assert" functions has a corresponding "assure" function; if the result is failure, the remaining tests in the unit test file are not run.


### Test Setup and Teardown

For steps that are common to all tests, setup and teardown functions may optionally be supplied.

```C++
#include <ArduinoUnitTests.h>

int* myNumber;

unittest_setup()
{
  myNumber = new int(4);
}

unittest_teardown()
{
  delete myNumber;
  myNumber = NULL;
}

unittest(your_test_name)
{
  assertEqual(4, *myNumber);
}

unittest_main()
```


# Build Scripts

For most build environments, the only script that need be executed by the CI system is

```shell
# simplest build script
bundle install
bundle exec arduino_ci.rb
```

However, more flexible usage is available:

### Custom Versions of external Arduino Libraries

Sometimes you need a fork of an Arduino library instead of the version that will be installed via their GUI.  `arduino_ci.rb` won't overwrite existing downloaded libraries with fresh downloads, but it won't fetch the custom versions for you either.

If this is the behavior you need, `ensure_arduino_installation.rb` is for you.  It ensures that an Arduino binary is available on the system.

```shell
# Example build script
bundle install

# ensure the Arduino installation -- creates the Library directory
bundle exec ensure_arduino_installation.rb

# manually install a custom library from a zip file
wget https://hosting.com/custom_library.zip
unzip -o custom_library.zip
mv custom_library $(bundle exec arduino_library_location.rb)

# manually install a custom library from a git repository
git clone https://repository.com/custom_library_repo.git
mv custom_library_repo $(bundle exec arduino_library_location.rb)

# now run CI
bundle exec arduino_ci.rb
```

Note the use of subshell to execute `bundle exec arduino_library_location.rb`.  This command simply returns the directory in which Arduino Libraries are (or should be) installed.



# Mocks of Arduino Hardware Functions

Unless your library peforms something general (e.g. a mathematical or string function, a data structure like Queue, etc), you may need to ensure that your code interacts properly with the Arduino hardware.  There are a series of mocks to assist in this.

## Using `GODMODE`

Complete control of the Arduino environment is available in your unit tests through a construct called `GODMODE()`.

```C++
unittest(example_godmode_stuff)
{
  GodmodeState* state = GODMODE();   // get access to the state
  state->reset();                    // does a full reset of the state.
  state->resetClock();               //  - you can reset just the clock (to zero)
  state->resetPins();                //  - or just the pins
  state->micros = 1;                 // manually set the clock such that micros() returns 1
  state->digitalPin[4];              // tells you the commanded state of digital pin 4
  state->digitalPin[4] = HIGH;       // digitalRead(4) will now return HIGH
  state->analogPin[3];               // tells you the commanded state of analog pin 3
  state->analogPin[3] = 99;          // analogRead(3) will now return 99
}
```

### Pin Histories

Of course, it's possible that your code might flip the bit more than once in a function.  For that scenario, you may want to examine the history of a pin's commanded outputs:

```C++
unittest(pin_history)
{
  GodmodeState* state = GODMODE();
  int myPin = 3;
  state->reset();            // pin will start LOW
  digitalWrite(myPin, HIGH);
  digitalWrite(myPin, LOW);
  digitalWrite(myPin, LOW);
  digitalWrite(myPin, HIGH);
  digitalWrite(myPin, HIGH);

  // pin history is queued in case we want to analyze it later.
  // we expect 6 values in that queue (5 that we set plus one
  // initial value), which we'll hard-code here for convenience.
  // (we'll actually assert those 6 values in the next block)
  assertEqual(6, state->digitalPin[1].queueSize());
  bool expected[6] = {LOW, HIGH, LOW, LOW, HIGH, HIGH};
  bool actual[6];

  // convert history queue into an array so we can verify it.
  // while we're at it, check that we received the amount of
  // elements that we expected.
  int numMoved = state->digitalPin[myPin].toArray(actual, 6);
  assertEqual(6, numMoved);

  // verify each element
  for (int i = 0; i < 6; ++i) {
    assertEqual(expected[i], actual[i]);
  }
}
```


### Pin Futures

Reading the pin more than once per function is also a possibility.  In that case, we want to queue up a few values for the `digitalRead` or `analogRead` to find.

```C++
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

  // for digital pins, we have the added possibility of specifying
  // a stream of input bytes encoded as ASCII
  bool bigEndian = true;
  state->digitalPin[1].fromAscii("Yo", bigEndian);

  // digitial history as serial data, big-endian
  bool expectedBits[16] = {
    0, 1, 0, 1, 1, 0, 0, 1,  // Y
    0, 1, 1, 0, 1, 1, 1, 1   // o
  };

  for (int i = 0; i < 16; ++i) {
    assertEqual(expectedBits[i], digitalRead(1));
  }
}
```

### Serial Data

Basic input and output verification of serial port data can be done as follows:

```c++
unittest(reading_writing_serial)
{
  GodmodeState* state = GODMODE();
  state->serialPort[0].dataIn = "";             // the queue of data waiting to be read
  state->serialPort[0].dataOut = "";            // the history of data written

  // When there is no data, nothing happens
  assertEqual(-1, Serial.peek());
  assertEqual("", state->serialPort[0].dataIn);
  assertEqual("", state->serialPort[0].dataOut);

  // if we put data on the input and peek at it, we see the value and it's not consumed
  state->serialPort[0].dataIn = "a";
  assertEqual('a', Serial.peek());
  assertEqual("a", state->serialPort[0].dataIn);
  assertEqual("", state->serialPort[0].dataOut);

  // if we read the input, we see the value and it's consumed
  assertEqual('a', Serial.read());
  assertEqual("", state->serialPort[0].dataIn);
  assertEqual("", state->serialPort[0].dataOut);

  // when we write data, it shows up in the history -- the output buffer
  Serial.write('b');
  assertEqual("", state->serialPort[0].dataIn);
  assertEqual("b", state->serialPort[0].dataOut);

  // when we print more data, note that the history
  // still contains the first thing we wrote
  Serial.print("cdefg");
  assertEqual("", state->serialPort[0].dataIn);
  assertEqual("bcdefg", state->serialPort[0].dataOut);
}
```

A more complicated example: working with serial port IO.  Let's say I have the following function:

```C++
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
```

This function has 3 side effects: it drains the serial port's receive buffer, affects a pin, and puts data in the serial port's send buffer.  Or, if the receive buffer is empty, it does nothing at all.

```C++
unittest(does_nothing_if_no_data)
{
    // configure initial state
    GodmodeState* state = GODMODE();
    int myPin = 3;
    state->serialPort[0].dataIn = "";
    state->serialPort[0].dataOut = "";
    state->digitalPin[myPin] = LOW;

    // execute action
    smartLightswitchSerialHandler(myPin);

    // assess final state
    assertEqual(LOW, state->digitalPin[myPin]);
    assertEqual("", state->serialPort[0].dataIn);
    assertEqual("", state->serialPort[0].dataOut);
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
```

### Pin History as ASCII


For additional complexity, there are some cases where you want to use a pin as a serial port.  There are history functions for that too.

```C++
  int myPin = 3;

  // digitial history as serial data, big-endian
  bool bigEndian = true;
  bool binaryAscii[24] = {
    0, 1, 0, 1, 1, 0, 0, 1,  // Y
    0, 1, 1, 0, 0, 1, 0, 1,  // e
    0, 1, 1, 1, 0, 0, 1, 1   // s
  };

  // "send" these bits
  for (int i = 0; i < 24; digitalWrite(myPin, binaryAscii[i++]));

  // The first bit in the history is the initial value, which we will ignore
  int offset = 1;

  // We should be able to parse the bits as ascii
  assertEqual("Yes", state->digitalPin[myPin].toAscii(offset, bigEndian));
```

Instead of queueing bits as ASCII for future use with `toAscii`, you can send those bits directly (and immediately) to the output using `outgoingFromAscii`.  Likewise, you can reinterpret/examine (as ASCII) the bits you have previously queued up by calling `incomingToAscii` on the PinHistory object.


### Interactivity of "Devices" with Observers

Even pin history and input/output buffers aren't capable of testing interactive code.  For example, queueing the canned responses from a serial device before the requests are even sent to it is not a sane test environment; the library under test will see the entire future waiting for it on the input pin instead of a buffer that fills and empties over time.  This calls for something more complicated.

In this example, we create a simple class to emulate a Hayes modem.  (For more information, dig into the `DataStreamObserver` code on which `DeviceUsingBytes` is based.

```c++
class FakeHayesModem : public DeviceUsingBytes {
  public:
    String mLast;

    FakeHayesModem() : DeviceUsingBytes() {
      mLast = "";
      addResponseLine("AT", "OK");
      addResponseLine("ATV1", "NO CARRIER");
    }
    virtual ~FakeHayesModem() {}
    virtual void onMatchInput(String output) { mLast = output; }
};

unittest(modem_hardware)
{
  GodmodeState* state = GODMODE();
  state->reset();
  FakeHayesModem m;
  m.attach(&Serial);

  Serial.write("AT\n");
  assertEqual("AT\n", state->serialPort[0].dataOut);
  assertEqual("OK\n", m.mLast);
}
```

Note that instead of setting `mLast = output` in the `onMatchInput()` function for test purposes, we could just as easily queue some bytes to state->serialPort[0].dataIn for the library under test to find on its next `peek()` or `read()`.  Or we could execute some action on a digital or analog input pin; the possibilities are fairly endless in this regard, although you will have to define them yourself -- from scratch -- extending the `DataStreamObserver` class to emulate your physical device.


### Interrupts

Although ISRs should be tested directly (as their asynchronous nature is not mocked), the act of attaching or detaching an interrupt can be measured.

```C++
unittest(interrupt_attachment) {
  GodmodeState *state = GODMODE();
  state->reset();
  assertFalse(state->interrupt[7].attached);
  attachInterrupt(7, (void (*)(void))0, 3);
  assertTrue(state->interrupt[7].attached);
  assertEqual(state->interrupt[7].mode, 3);
  detachInterrupt(7);
  assertFalse(state->interrupt[7].attached);
}
```


### SPI

These basic mocks of SPI store the values in Strings.

```C++
unittest(spi) {
  GodmodeState *state = GODMODE();

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
```

### EEPROM

`EEPROM` is a global with a simple API to read and write bytes to persistent memory (like a tiny hard disk) given an `int` location. Since the Arduino core already provides this as a global, and the core API is sufficient for basic testing (read/write), there is no direct tie to the `GODMODE` API. (If you need more, such as a log of intermediate values, enter a feature request.)

```C++
unittest(eeprom)
{
  uint8_t a;
  // size
  assertEqual(EEPROM_SIZE, EEPROM.length());
  // initial values
  a = EEPROM.read(0);
  assertEqual(255, a);
  // write and read
  EEPROM.write(0, 24);
  a = EEPROM.read(0);
  assertEqual(24, a);
  // update
  EEPROM.write(1, 14);
  EEPROM.update(1, 22);
  a = EEPROM.read(1);
  assertEqual(22, a);
  // put and get
  const float f1 = 0.025f;
  float f2 = 0.0f;
  EEPROM.put(5, f1);
  assertEqual(0.0f, f2);
  EEPROM.get(5, f2);
  assertEqual(0.025f, f2);
  // array access
  int val = 10;
  EEPROM[2] = val;
  a = EEPROM[2];
  assertEqual(10, a);
}
```


### Wire

This library allows communication with I2C / TWI devices.

The interface the library has been fully mocked, with the addition of several functions for debugging

* `Wire.resetMocks()`: Initializes all mocks, and for test repeatability should be called at the top of any unit tests that use Wire.
* `Wire.didBegin()`: returns whether `Wire.begin()` was called at any point
* `Wire.getMosi(address)`: returns a pointer to a `deque` that represents the history of data sent to `address`
* `Wire.getMiso(address)`: returns a pointer to a `deque` that defines what the master will read from `address` (i.e. for you to supply)

```c++
unittest(wire_basics) {
  // ensure known starting state
  Wire.resetMocks();

  // in case you need to check that your library is properly calling .begin()
  assertFalse(Wire.didBegin());
  Wire.begin();
  assertTrue(Wire.didBegin());

  // pick a random device. master write buffer should be empty
  const uint8_t randomSlaveAddr = 14;
  deque<uint8_t>* mosi = Wire.getMosi(randomSlaveAddr);
  assertEqual(0, mosi->size());

  // write some random data to random device
  const uint8_t randomData[] = { 0x07, 0x0E };
  Wire.beginTransmission(randomSlaveAddr);
  Wire.write(randomData[0]);
  Wire.write(randomData[1]);
  Wire.endTransmission();

  // check master write buffer values
  assertEqual(2, mosi->size());
  assertEqual(randomData[0], mosi->front());
  mosi->pop_front();
  assertEqual(randomData[1], mosi->front());
  mosi->pop_front();
  assertEqual(0, mosi->size());
}
```
