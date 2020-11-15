Arduino Sample Projects
=======================

This directory contains projects that are intended solely for testing the various features of this gem -- to test the testing framework itself.  The RSpec tests refer specifically to these projects.

Because of this, these projects include some intentional quirks that differ from what a well-formed an Arduino project for testing with `arduino_ci` might contain.  See other projects in the "Arduino-CI" GitHub organization for practical examples.


* "TestSomething" contains a minimial library, but tests for all the C++ compilation feature-mocks of arduino_ci.
* "DoSomething" is a simple test of the testing framework (arduino_ci) itself to verfy that passes and failures are properly identified and reported.  Because of this, it includes test files that are expected to fail -- they are prefixed with "bad-".
* "OnePointOhDummy" is a non-functional library meant to test file inclusion logic on libraries conforming to the "1.0" specification
* "OnePointFiveMalformed" is a non-functional library meant to test file inclusion logic on libraries that attempt to conform to the ["1.5" specfication](https://arduino.github.io/arduino-cli/latest/library-specification/) but fail to include a `src` directory
* "OnePointFiveDummy" is a non-functional library meant to test file inclusion logic on libraries conforming to the ["1.5" specfication](https://arduino.github.io/arduino-cli/latest/library-specification/)
* "DependOnSomething" is a non-functional library meant to test file inclusion logic with dependencies
* "ExcludeSomething" is a non-functional library meant to test directory exclusion logic
