# Arduino CI and Unit Tests HOWTO [![Build Status](https://travis-ci.org/ifreecarve/arduino-ci-unit-tests.svg?branch=master)](https://travis-ci.org/ifreecarve/arduino-ci-unit-tests)

This project is a template for a CI-enabled (and unit testable) Arduino project of your own.


### Features

* Travis CI
* Unit tests
* Development workflow matches CI workflow - the `platformio ci` line at the bottom of `.travis.yml` can be run on your local terminal (just append the name of the file you want to compile).

# Where The Magic Happens

Here is the minimal set of files that you will need to adapt to your own project:

* `.travis.yml` - You'll need to fill in the `env` section with files relevant to your project, and list out all the `--board`s under the `script` section.
* `platformio.ini` - You'll need to add information for any architectures you plan to support.
* `library.properties` - You'll need to update the `architectures` and `includes` lines as appropriate


# Credits

This Arduino example was created in January 2018 by Ian Katz <ianfixes@gmail.com>.
