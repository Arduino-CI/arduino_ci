# Arduino CI and Unit Tests HOWTO

This project is a template for a CI-enabled (and unit testable) Arduino project of your own.


### Features

* Travis CI
* Unit tests
* Development workflow matches CI workflow

# Where The Magic Happens

Here is the minimal set of files that you will need to adapt to your own project:


### `Gemfile` Ruby gem configuration

```ruby
source 'https://rubygems.org'
gem 'arduino_ci'
```

You'll need this to get access to the functionality.

> This is different from the `Gemfile` that's included in this directory!  That's for purposes of testing the ruby gem that also lives in this repository.  So "do as I say, not as I do", in this case.


### `.travis.yml` Travis CI configuration

At a minimum, you will need the following lines in your file:

```yaml
language: ruby
script:
   - bundle install
   - bundle exec arduino_ci_remote.rb
```

This will install the necessary ruby gem, and run it.  There are no command line arguments as of this writing, because all configuration is provided by...

### `.arduino-ci.yaml` ArduinoCI configuration

This file controls all aspects of building and unit testing.  The (relatively-complete) defaults can be found [in the base project](../../misc/default.yaml).

The most relevant sections for most projects will be as follows:

```yaml
compile:
  libraries: ~
  platforms:
    - uno
    - due
    - leonardo

unittest:
  libraries: ~
  platforms:
    - uno
    - due
    - leonardo
```

This does nothing but specify a list of what platforms should run each set of tests.  The platforms themselves can also be defined and/or extended in the yaml file.  For example, `esp8266` as shown here:

```yaml
platforms:
  esp8266:
    board: esp8266:esp8266:huzzah
    package: esp8266:esp8266
    gcc:
      features:
      defines:
      warnings:
      flags:
```

Of course, this wouldn't work by itself -- the Arduino IDE would have to know how to install the package via the board manager.  So there's a section for packages too:

```yaml
packages:
  esp8266:esp8266:
    url: http://arduino.esp8266.com/stable/package_esp8266com_index.json
```

### Unit tests in `test/`

All `.cpp` files in the `test/` directory are assumed to contain unit tests.  Each and every one will be compiled and executed on its own.

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

This test defines one `unittest` (a macro provided by `ArduinoUnitTests.h`), called `your_test_name`, which makes some assertions on the target library.  The `int main` section is boilerplate.


# Credits

This Arduino example was created in January 2018 by Ian Katz <ianfixes@gmail.com>.
