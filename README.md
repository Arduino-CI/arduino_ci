
# ArduinoCI Ruby gem (`arduino_ci`)
[![Gem Version](https://badge.fury.io/rb/arduino_ci.svg)](https://rubygems.org/gems/arduino_ci)
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/gems/arduino_ci/1.3.0)
[![Gitter](https://badges.gitter.im/Arduino-CI/arduino_ci.svg)](https://gitter.im/Arduino-CI/arduino_ci?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![GitHub Marketplace](https://img.shields.io/badge/Get_it-on_Marketplace-informational.svg)](https://github.com/marketplace/actions/arduino_ci)

Arduino CI was created to enable better collaboration among Arduino library maintainers and contributors, by enabling automated code checks to be performed as part of a pull request process.

* enables running unit tests against the library **without hardware present**
* provides a system of mocks that allow fine-grained control over the hardware inputs, including the system's clock
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

This project has the following dependencies:

* `ruby` 2.5 or higher
* A compiler like `g++` (on OSX, `clang` works; on Cygwin, use the `mingw-gcc-c++` package)
* `python` (if using a board architecutre that requires it, e.g. ESP32, ESP8266; see [this issue](https://github.com/Arduino-CI/arduino_ci/issues/235#issuecomment-739629243)). Consider `pyserial` as well.

In that environment, you can install by running `gem install arduino_ci`.  To update to a latest version, use `gem update arduino_ci`.

You can now test your library by simply running the command `arduino_ci.rb` from your library directory.  This will perform the following:

* validation of some fields in `library.properties`, if it exists
* running unit tests from files found in `test/`, if they exist
* testing compilation of example sketches found in `examples/`, if they exist

### Assumptions About Your Repository

Arduino expects all libraries to be in a specific `Arduino/libraries` directory on your system.  If your library is elsewhere, `arduino_ci` will _automatically_ create a symbolic link in the `libraries` directory that points to the directory of the project being tested.  This simplifieds working with project dependencies, but **it can have unintended consequences on Windows systems**.

> If you use a Windows system **it is recommended that you only run `arduino_ci` from project directories that are already inside the `libraries` directory** because [in some cases deleting a folder that contains a symbolic link to another folder can cause the _entire linked folder_ to be removed instead of just the link itself](https://superuser.com/a/306618).

### Changes to Your Repository

Unit testing binaries created by `arduino_ci` should not be commited to the codebase.  To avoid that, add the following to your `.gitignore`:

```ignore-list
# arduino_ci unit test binaries and artifacts
*.bin
*.bin.dSYM
```

### A Quick Example

For a fairly minimal practical example of a unit-testable library repo that you can copy from, see [the `Arduino-CI/Blink` repository](https://github.com/Arduino-CI/Blink).


## Advanced Start

New features and bugfixes reach GitHub before they reach a released ruby gem.  Alternately, it may be that (for your own reasons) you do not wish to install `arduino_ci` globally on your system.  A few additional setup steps are required if you wish to do this.

### You Need Ruby _and_ Bundler

In addition to version 2.5 or higher, you'll also need to `gem install bundler` to a minimum of version 2.0 if it's not already there.  You may find it easiest to do this by using [`rbenv`](https://github.com/rbenv/rbenv).

You will need to add a file called `Gemfile` (no extension) to your Arduino project.

#### Non-root installation

If you are simply trying to avoid the need to install `arduino_ci` system-wide (which may require administrator permissions), your `Gemfile` would look like this:

```ruby
source 'https://rubygems.org'

# Replace 1.2 with the desired version of arduino_ci.  See https://guides.rubygems.org/patterns/#pessimistic-version-constraint
gem 'arduino_ci', '~> 1.2'
```

It would also make sense to add the following to your `.gitignore`:
```ignore-list
/.bundle/
vendor
```

> Note: this used to be the recommended installation method, but with the library's maturation it's better to avoid the use of `Gemfile` and `bundle install` by just installing as per the "Quick Start" instructions above.


#### Using the latest-available code

If you want to use the latest code on GitHub, your `Gemfile` would look like this:

```ruby
source 'https://rubygems.org'

# to use the latest github code in a given repo and branch, replace the below values for git: and ref: as needed
gem 'arduino_ci', git: 'https://github.com/ArduinoCI/arduino_ci.git', ref: '<your desired ref, branch, or tag>'
```


#### Using a version of `arduino_ci` source code on your local machine

First, Thanks!  See [CONTRIBUTING.md](CONTRIBUTING.md).  Your `Gemfile` would look like this:

```ruby
source 'https://rubygems.org'

gem 'arduino_ci', path: '/path/to/development/dir/for/arduino_ci'
```


### Installing the Dependencies

Fulfilling the `arduino_ci` library dependency is as easy as running either of these two commands:
```
$ bundle install   # adds packages to global library (may require admin rights)
$ bundle install --path vendor/bundle   # adds packages to local library
```

This will create a `Gemfile.lock` in your project directory, which you may optionally check into source control.  A broader introduction to ruby dependencies is outside the scope of this document.



### Running `arduino_ci.rb` To Test Your Library

With that installed, just the following shell command each time you want the tests to execute:

```console
$ bundle exec arduino_ci.rb
```


### Reference

For more information on the usage of `arduino_ci.rb`, see [REFERENCE.md](REFERENCE.md).  It contains information such as:

* How to configure build options (platforms to test, Arduino library dependencies to install) with an `.arduino-ci.yml` file
* Where to put unit test files
* How to structure unit test files
* How to control the global (physical) state of the Arduino board
* How to modify the Arduino platforms, compilers, test plans, etc


## Setting up Pull Request Testing and/or External CI

> **Note:** `arduino_ci.rb` expects to be run from the root directory of your Arduino project library.

### Arduino CI's Own GitHub action

[![GitHub Marketplace](https://img.shields.io/badge/Get_it-on_Marketplace-informational.svg)](https://github.com/marketplace/actions/arduino_ci)


### Your Own Scripted GitHub Action

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
          gem install arduino_ci
          arduino_ci.rb
```


### Travis CI

You'll need to go to https://travis-ci.org/profile/ and enable testing for your Arduino project.  Once that happens, you should be all set.  The script will test all example projects of the library and all unit tests.

Next, you need this in `.travis.yml` in your repo

```yaml
sudo: false
language: ruby
script:
  - gem install arduino_ci
  - arduino_ci.rb
```


### Appveyor CI

You'll need to go to https://ci.appveyor.com/projects and add your project.

Next, you'll need this in `appveyor.yml` in your repo.

```yaml
build: off
test_script:
  - gem install arduino_ci
  - arduino_ci.rb
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
