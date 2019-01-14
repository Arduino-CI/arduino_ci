
# ArduinoCI Ruby gem (`arduino_ci`) [![Gem Version](https://badge.fury.io/rb/arduino_ci.svg)](https://rubygems.org/gems/arduino_ci) [![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/gems/arduino_ci/0.1.17)

You want your Arduino library to be automatically built and tested every time someone contributes code to your project on GitHub, but the Arduino IDE lacks the ability to run unit tests. [Arduino CI](https://github.com/ianfixes/arduino_ci) provides that ability.

You want to run tests on your Arduino library without hardware present, but the IDE doesn't support that.  Arduino CI provides that ability.

You want to precisely replicate certain software states in your library, but you don't have sub-millisecond reflexes for physically faking the inputs, outputs, and serial port.   Arduino CI fakes 100% of the physical input and output of an Arduino board, including the clock.

`arduino_ci` is a cross-platform build/test system, consisting of a Ruby gem and a series of C++ mocks.  It enables tests to be run both locally and as part of a CI service like Travis or Appveyor.  Any OS that can run the Arduino IDE can run `arduino_ci`.

Platform | CI Status
---------|:---------
OSX      | [![OSX Build Status](http://badges.herokuapp.com/travis/ianfixes/arduino_ci?env=BADGE=osx&label=build&branch=master)](https://travis-ci.org/ianfixes/arduino_ci)
Linux    | [![Linux Build Status](http://badges.herokuapp.com/travis/ianfixes/arduino_ci?env=BADGE=linux&label=build&branch=master)](https://travis-ci.org/ianfixes/arduino_ci)
Windows  | [![Windows Build status](https://ci.appveyor.com/api/projects/status/8f6e39dea319m83q/branch/master?svg=true)](https://ci.appveyor.com/project/ianfixes/arduino-ci)


## Installation In Your GitHub Project And Using Travis CI

The following prerequisites must be fulfilled:

* A compiler; [g++](https://gcc.gnu.org/) is preferred.  On OSX, this is provided by the built-in `clang`.
* A GitHub (or other repository-hosting) project for your library
* A CI system like Travis or Appveor that is linked to your project


### Changes to Your Repo

Add a file called `Gemfile` (no extension) to your Arduino project:

```ruby
source 'https://rubygems.org'
gem 'arduino_ci'
```

### Testing Locally

First, pull in the `arduino_ci` library as a dependency.

```
$ bundle install
```


With that installed, just the following shell command each time you want the tests to execute:

```
$ bundle exec arduino_ci_remote.rb
```



### Testing with remote CI

> **Note:** `arduino_ci_remote.rb` expects to be run from the root directory of your Arduino project library.


#### Travis CI

You'll need to go to https://travis-ci.org/profile/ and enable testing for your Arduino project.  Once that happens, you should be all set.  The script will test all example projects of the library and all unit tests.

Next, you need this in `.travis.yml` in your repo

```yaml
sudo: false
language: ruby
script:
   - bundle install
   - bundle exec arduino_ci_remote.rb
```

#### Appveyor CI

You'll need to go to https://ci.appveyor.com/projects and add your project.

Next, you'll need this in `appveyor.yml` in your repo.

```yaml
build: off
test_script:
  - bundle install
  - bundle exec arduino_ci_remote.rb
```

## Quick Start

This software is in beta.  But [SampleProjects/DoSomething](SampleProjects/DoSomething) has a decent writeup and is a good bare-bones example of all the features.

## Reference

For more information on the usage of `arduino_ci`, see [REFERENCE.md](REFERENCE.md).  It contains information such as:

* Where to put unit test files
* How to structure unit test files
* How to control the global (physical) state of the Arduino board
* How to modify the Arduino platforms, compilers, test plans, etc


## Known Problems

* The Arduino library is not fully mocked.
* I don't have preprocessor defines for all the Arduino board flavors
* https://github.com/ianfixes/arduino_ci/issues


## Comparison to Other Arduino Testing Tools


| Project | CI | Builds Examples | Unittest | Arduino Mocks | Windows | OSX | Linux | License |
|---------|----|-----------------|----------|---------------|---------|-----|-------|---------|
|[ArduinoCI](https://github.com/ianfixes/arduino_ci)| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |Free (Apache-2.0)|
|[ArduinoUnit](https://github.com/mmurdoch/arduinounit)|❌ |❌ |Hardware-based|❌ | ✅ | ✅ | ✅ |Free (MIT)| |
|[Adafruit `travis-ci-arduino`](https://github.com/adafruit/travis-ci-arduino)   | ✅ | ✅ | ❌| ❌ | ❌ | ❌ | ✅ |Free (MIT)|
|[PlatformIO](https://platformio.org)| ✅ | ✅ | Paid only | ❌ | ✅ | ✅ | ✅ |Proprietary (EULA)|

## Author

This gem was written by Ian Katz (ianfixes@gmail.com) in 2018.  It's released under the Apache 2.0 license.


## See Also

* [Contributing](CONTRIBUTING.md)
* [Adafruit/travis-ci-arduino](https://github.com/adafruit/travis-ci-arduino) which inspired this project
* [mmurdoch/arduinounit](https://github.com/mmurdoch/arduinounit) from which the unit test macros were adopted

