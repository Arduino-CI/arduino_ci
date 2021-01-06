
# ArduinoCI Ruby gem (`arduino_ci`)
[![Gem Version](https://badge.fury.io/rb/arduino_ci.svg)](https://rubygems.org/gems/arduino_ci)
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/gems/arduino_ci/1.1.0)
[![Gitter](https://badges.gitter.im/Arduino-CI/arduino_ci.svg)](https://gitter.im/Arduino-CI/arduino_ci?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![GitHub Marketplace](https://img.shields.io/badge/Get_it-on_Marketplace-informational.svg)](https://github.com/marketplace/actions/arduino_ci)

Arduino CI was created to enable better collaboration among Arduino library maintainers and contributors, by enabling automated code checks to be performed as part of a pull request process.

* enables running unit tests against the library **without hardware present**
* provides a system of mocks that allow fine-grained control over the hardare inputs, including the system's clock
* verifies compilation of any example sketches included in the library
* can test a wide range of arduino boards with different hardware options available
* compares entries in `library.properties` to the contents of the library and reports mismatches
* can be run both locally and as part of CI (GitHub Actions, TravisCI, Appveyor, etc.)
* runs on multiple platforms -- any platform that supports the Arduino IDE
* provides detailed analysis of segfaults in compilers that support such debugging features

> Note: for running tests in response to [GitHub events](https://docs.github.com/en/free-pro-team@latest/developers/webhooks-and-events/github-event-types), an [Arduino CI GitHub Action](https://github.com/marketplace/actions/arduino_ci) is available for your convenience.  This method of running `arduino_ci` is driven by Docker, which may also serve your local testing needs (as it does not require a ruby environment to be installed).

Arduino CI works on multiple platforms, which should enable your CI system of choice to leverage it for testing.

Platform | CI Status
---------|:---------
OSX      | [![OSX Build Status](https://github.com/Arduino-CI/arduino_ci/workflows/macos/badge.svg)](https://github.com/Arduino-CI/arduino_ci/actions?workflow=macos)
Linux    | [![Linux Build Status](https://github.com/Arduino-CI/arduino_ci/workflows/linux/badge.svg)](https://github.com/Arduino-CI/arduino_ci/actions?workflow=linux)
Windows  | [![Windows Build status](https://github.com/Arduino-CI/arduino_ci/workflows/windows/badge.svg)](https://github.com/Arduino-CI/arduino_ci/actions?workflow=windows)


## Quick Start

### You Need Your Arduino Library

For a fairly minimal practical example of a unit-testable library repo that you can copy from, see [the `Arduino-CI/Blink` repository](https://github.com/Arduino-CI/Blink).

> Note: The `SampleProjects` directory you see within _this_ repo contains tests for validing the `arduino_ci` framework itself, and due to that coupling will not be helpful to duplicate.  That said, the [SampleProjects/TestSomething](SampleProjects/TestSomething) project contains [test files](SampleProjects/TestSomething/test/) (each named after the type of feature being tested) that may be illustrative of testing strategy and capabilities _on an individual basis_.

Arduino expects all libraries to be in a specific `Arduino/libraries` directory on your system.  If your library is elsewhere, `arduino_ci` will _automatically_ create a symbolic link in the `libraries` directory that points to the directory of the project being tested.  This simplifieds working with project dependencies, but **it can have unintended consequences on Windows systems**.

> If you use a Windows system **it is recommended that you only run `arduino_ci` from project directories that are already inside the `libraries` directory** because [in some cases deleting a folder that contains a symbolic link to another folder can cause the _entire linked folder_ to be removed instead of just the link itself](https://superuser.com/a/306618).


### You Need Ruby and Bundler

You'll need Ruby version 2.5 or higher, and to `gem install bundler` if it's not already there.


### You Need A Compiler (`g++`)

For unit testing, you will need a compiler; [g++](https://gcc.gnu.org/) is preferred.

* **Linux**: `gcc`/`g++` is likely pre-installed.
* **OSX**: `g++` is an alias for `clang`, which is provided by Xcode and the developer tools.  You are free to `brew install gcc` as well; this is also tested and working.
* **Windows**: you will need Cygwin, and the `mingw-gcc-g++` package.


### You _May_ Need `python`

ESP32 and ESP8266 boards have [a dependency on `python` that they don't install themselves](https://github.com/Arduino-CI/arduino_ci/issues/235#issuecomment-739629243).  If you intend to test on these platforms (which are included in the default list of platforms to test against), you will need to make `python` (and possibly `pyserial`) available in the test environment.

Alternately, you might configure `arduino_ci` to simply not test against these.  Consult the reference for those details.


### Changes to Your Repo

Add a file called `Gemfile` (no extension) to your Arduino project:

```ruby
source 'https://rubygems.org'
gem 'arduino_ci' '~> 1.1'
```

At the time of this writing, `1.1` is the latest version available, and the `~>` syntax will allow your system to update it to the latest `1.x.x` version.  The list of all available versions can be found on [rubygems.org](https://rubygems.org/gems/arduino_ci) if you prefer to explicitly pin a higher version.

It would also make sense to add the following to your `.gitignore`, or copy [the `.gitignore` used by this project](.gitignore):

```
/.bundle/
/.yardoc
Gemfile.lock
/_yardoc/
/coverage/
/doc/
/pkg/
/spec/reports/
vendor
*.gem

# rspec failure tracking
.rspec_status

# C++ stuff
*.bin
*.bin.dSYM
```


### Installing the Dependencies

Fulfilling the `arduino_ci` library dependency is as easy as running either of these two commands:
```
$ bundle install   # adds packages to global library (may require admin rights)
$ bundle install --path vendor/bundle   # adds packages to local library
```


### Running tests

With that installed, just the following shell command each time you want the tests to execute:

```
$ bundle exec arduino_ci.rb
```

`arduino_ci.rb` is the main entry point for this library.  This command will iterate over all the library's `examples/` and attempt to compile them.  If you set up unit tests, it will run those as well.


### Reference

For more information on the usage of `arduino_ci.rb`, see [REFERENCE.md](REFERENCE.md).  It contains information such as:

* How to configure build options (platforms to test, Arduino library dependencies to install) with an `.arduino-ci.yml` file
* Where to put unit test files
* How to structure unit test files
* How to control the global (physical) state of the Arduino board
* How to modify the Arduino platforms, compilers, test plans, etc


## Setting up Pull Request Testing and/or External CI

The following prerequisites must be fulfilled:

* A GitHub (or other repository-hosting) project for your library
* A CI system like [Travis CI](https://travis-ci.org/) or [Appveyor](https://www.appveyor.com/) that is linked to your project


### Testing with remote CI

> **Note:** `arduino_ci.rb` expects to be run from the root directory of your Arduino project library.


#### GitHub Actions

GitHub Actions allows you to automate your workflows directly in GitHub.
No additional steps are needed.
Just create a YAML file with the information below in your repo under the `.github/workflows/` directory.

```yaml
on: [push, pull_request]
jobs:
  runTest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 2.6
      - run: |
          bundle install
          bundle exec arduino_ci_remote.rb
```


#### Travis CI

You'll need to go to https://travis-ci.org/profile/ and enable testing for your Arduino project.  Once that happens, you should be all set.  The script will test all example projects of the library and all unit tests.

Next, you need this in `.travis.yml` in your repo

```yaml
sudo: false
language: ruby
script:
  - bundle install
  - bundle exec arduino_ci.rb
```


#### Appveyor CI

You'll need to go to https://ci.appveyor.com/projects and add your project.

Next, you'll need this in `appveyor.yml` in your repo.

```yaml
build: off
test_script:
  - bundle install
  - bundle exec arduino_ci.rb
```


## Known Problems

* The Arduino library is not fully mocked, nor is `avr-libc`.
* I don't have preprocessor defines for all the Arduino board flavors
* https://github.com/Arduino-CI/arduino_ci/issues


## Author

This gem was written by Ian Katz (ianfixes@gmail.com) in 2018.  It's released under the Apache 2.0 license.


## See Also

* [Contributing](CONTRIBUTING.md)
* [Adafruit/ci-arduino](https://github.com/adafruit/ci-arduino) which inspired this project
* [mmurdoch/arduinounit](https://github.com/mmurdoch/arduinounit) from which the unit test macros were adopted
