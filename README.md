[![Gem Version](https://badge.fury.io/rb/arduino_ci.svg)](https://rubygems.org/gems/arduino_ci)
[![Build Status](https://travis-ci.org/ifreecarve/arduino_ci.svg)](https://travis-ci.org/ifreecarve/arduino_ci)
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/gems/arduino_ci/0.1.0)

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

That's literally all there is to it on the repository side.  You'll need to go to https://travis-ci.org/profile/ and enable testing for your Arduino project.  Once that happens, you should be all set.


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
