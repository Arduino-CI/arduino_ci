#include <ArduinoUnitTests.h>
#include <Arduino.h>

// the setup for the debouncing function that we will test
// via https://www.arduino.cc/en/Tutorial/BuiltInExamples/Debounce
//  ... condensed for brevity
//
// pretend that sketch is a library function that is run on every loop
// e.g.
//   void loop() { onLoop(); }
//
const int buttonPin = 2;          // the number of the pushbutton pin
const int ledPin = 13;            // the number of the LED pin
const long debounceDelay = 50;    // debounce time; increase if the output flickers
int ledState;                     // current state of the output pin
int buttonState;                  // current reading from the input pin
int lastButtonState;              // previous reading from the input pin
unsigned long lastDebounceTime;   // last time the output pin was toggled

void onLoop() {
  // read state, record time if the input flipped
  int reading = digitalRead(buttonPin);
  if (reading != lastButtonState) lastDebounceTime = millis();

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading != buttonState) {
      buttonState = reading;
      if (buttonState == HIGH) ledState = !ledState;
      digitalWrite(ledPin, ledState);
    }
  }

  lastButtonState = reading;
}


/////////// Unit tests
//
// This isn't an exhaustive test of states and transitions. Consider permutations of the following variables:
//   - ledState
//   - buttonState
//   - lastButtonState
//   - the actual digital value on the input
//   - the current time relative to the last debounce time
//
// But we will test a few bounces: 0 transitions, 1 transition, and 3 transitions.
// The general pattern is
//  0. set the initial software state
//  1. set the hardware state (including clock)
//  2. call the library function
//  3. validate software state and hardware output state against expectations
// repeat steps 1-3 as necessary for changing inputs

// Declare state and reset it for each test
GodmodeState* state = GODMODE();
unittest_setup() {
  state->reset();
}

unittest(nothing_happens_if_button_isnt_pressed) {
  // initial library state
  ledState         = LOW;
  buttonState      = LOW;
  lastButtonState  = LOW;
  lastDebounceTime = 0;

  state->micros    = 0;
  assertEqual(LOW, state->digitalPin[buttonPin]);           // initial input low (default)
  assertEqual(1, state->digitalPin[ledPin].historySize());  // initial output history has 1 entry so far (low)

  onLoop();
  assertEqual(LOW, state->digitalPin[ledPin]);      // nothing has changed on the hardware end
  assertEqual(LOW, lastButtonState);
  assertEqual(0, state->micros);                    // remember, only we can advance the clock
  assertEqual(0, lastDebounceTime);

  state->micros = 50001;                            // advance the clock
  onLoop();
  assertEqual(LOW, state->digitalPin[ledPin]);      // still no change
  assertEqual(LOW, lastButtonState);
  assertEqual(0, lastDebounceTime);
}

unittest(perfectly_clean_low_to_high) {
  ledState                     = LOW;
  buttonState                  = LOW;
  lastButtonState              = LOW;
  lastDebounceTime             = 0;
  state->micros                = 25000;
  state->digitalPin[buttonPin] = HIGH;                     // set initial button entry to HIGH

  onLoop();
  assertEqual(LOW, state->digitalPin[ledPin]);
  assertEqual(HIGH, lastButtonState);
  assertEqual(LOW, ledState);
  assertEqual(25, lastDebounceTime);
  assertEqual(1, state->digitalPin[ledPin].historySize()); //  no change in output

  // actual boundary case
  state->micros = 75999;
  onLoop();
  assertEqual(LOW, state->digitalPin[ledPin]);
  assertEqual(HIGH, lastButtonState);
  assertEqual(LOW, ledState);
  assertEqual(25, lastDebounceTime);
  assertEqual(1, state->digitalPin[ledPin].historySize()); //  no change in output

  // actual boundary case for exact timing
  state->micros = 76000;
  onLoop();
  assertEqual(HIGH, state->digitalPin[ledPin]);
  assertEqual(HIGH, lastButtonState);
  assertEqual(HIGH, ledState);
  assertEqual(25, lastDebounceTime);
  assertEqual(2, state->digitalPin[ledPin].historySize()); //  output was written
}

unittest(bounce_low_to_high) {
  ledState                     = LOW;
  buttonState                  = LOW;
  lastButtonState              = LOW;
  lastDebounceTime             = 0;

  state->micros                = 25000;
  state->digitalPin[buttonPin] = HIGH;                     // set initial button entry to HIGH
  onLoop();
  assertEqual(25, lastDebounceTime);                       // debounce time has reset
  assertEqual(LOW, state->digitalPin[ledPin]);             // no change in output
  assertEqual(HIGH, lastButtonState);

  state->micros                = 50000;
  state->digitalPin[buttonPin] = LOW;                      // bounce button LOW
  onLoop();
  assertEqual(50, lastDebounceTime);                       // debounce time has reset
  assertEqual(LOW, state->digitalPin[ledPin]);             // no change in LED output
  assertEqual(LOW, lastButtonState);

  state->micros                = 75000;
  state->digitalPin[buttonPin] = HIGH;                     // bounce button HIGH
  onLoop();
  assertEqual(75, lastDebounceTime);                       // debounce time is again reset
  assertEqual(LOW, state->digitalPin[ledPin]);             // still no change in LED output
  assertEqual(HIGH, lastButtonState);

  state->micros                = 126000;                   // actual boundary case, time elapsed
  state->digitalPin[buttonPin] = HIGH;
  onLoop();
  assertEqual(75, lastDebounceTime);                       // no additional bounce happened
  assertEqual(HIGH, state->digitalPin[ledPin]);            // therefore the LED turns on
  assertEqual(2, state->digitalPin[ledPin].historySize()); // digital output was written only once
}

unittest_main()
