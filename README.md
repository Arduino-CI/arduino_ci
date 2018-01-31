[![Gem Version](https://badge.fury.io/rb/arduino_ci.svg)](https://rubygems.org/gems/arduino_ci)
[![Build Status](https://travis-ci.org/ifreecarve/arduino_ci.svg)](https://travis-ci.org/ifreecarve/arduino_ci)
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/gems/arduino_ci/0.1.3)

# ArduinoCI Ruby gem (`arduino_ci`)

[Arduino CI](https://github.com/ifreecarve/arduino_ci) is a Ruby gem for executing Continuous Integration (CI) tests on an Arduino library -- both locally and as part of a service like Travis CI.


## Installation In Your GitHub Project And Using Travis CI

Add a file called `Gemfile` (no extension) to your Arduino project:

```ruby
source 'https://rubygems.org'
gem 'arduino_ci'
```

Next, you need this in `.travis.yml`

```yaml
sudo: false
language: ruby
script:
   - bundle install
   - bundle exec arduino_ci_remote.rb
```

That's literally all there is to it on the repository side.  You'll need to go to https://travis-ci.org/profile/ and enable testing for your Arduino project.  Once that happens, you should be all set.  The script will test all example projects of the library and all unit tests.

### Unit tests in `test/`

All `.cpp` files in the `test/` directory of your Arduino library are assumed to contain unit tests.  Each and every one will be compiled and executed on its own.

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

This test defines one `unittest` (a macro provided by `ArduionUnitTests.h`), called `your_test_name`, which makes some assertions on the target library.  The `unittest_main()` is a macro for the `int main()` boilerplate required for unit testing.


### Using `GODMODE`

Complete control of the Arduino environment is available in your unit tests through a construct called `GODMODE()`.

```C++
unittest(example_godmode_stuff)
{
  GodmodeState* state = GODMODE();   // get access to the state
  state->reset();                    // does a full reset of the state.
  state->resetClock();               //  - you can reset just the clock (to zero)
  state->resetPins();                //  - or just the pins
  state->micros = 1;                 // manually set the clock such that micros() returns 1
  state->digitalPin[4];              // stores the commanded state of digital pin 4
  state->digitalPin[4] = HIGH;       // digitalRead(4) will now return HIGH
  state->analogPin[3];               // stores the commanded state of analog pin 3
  state->analogPin[3] = 99;          // analogRead(3) will now return 99
}
```


## More Documentation

This software is in alpha.  But [SampleProjects/DoSomething](SampleProjects/DoSomething) has a decent writeup and is a good bare-bones example of all the features.

## Known Problems

* The Arduino library is not fully mocked.
* I don't have preprocessor defines for all the Arduino board flavors
* Arduino Zero boards don't work in CI.  I'm confused.
* https://github.com/ifreecarve/arduino_ci/issues


## Author

This gem was written by Ian Katz (ifreecarve@gmail.com) in 2018.  It's released under the Apache 2.0 license.


## See Also

* [Contributing](CONTRIBUTING.md)
* [Adafruit/travis-ci-arduino](https://github.com/adafruit/travis-ci-arduino) which inspired this project
* [mmurdoch/arduinounit](https://github.com/mmurdoch/arduinounit) from which the unit test macros were adopted
