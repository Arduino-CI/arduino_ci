# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).


## [Unreleased]
### Added
- `arduino_ci_remote.rb` CLI switch `--skip-examples-compilation`
- Add support for `diditalPinToPort()`, `digitalPinToBitMask()`, `portOutputRegister()`, and `portInputRegister()`
- `CppLibrary.header_files` to find header files
- `LibraryProperties` to read metadata from Arduino libraries
- `CppLibrary.library_properties_path`, `CppLibrary.library_properties?`, `CppLibrary.library_properties` to expose library properties of a Cpp library
- `CppLibrary.arduino_library_dependencies` to list the dependent libraries specified by the library.properties file
- `CppLibrary.print_stack_dump` prints stack trace dumps (on Windows specifically) to the console if encountered
- Definitions for Arduino zero
- Support for mock EEPROM (but only if board supports it)
- Add stubs for `Client.h`, `IPAddress.h`, `Printable.h`, `Server.h`, and `Udp.h`
- Sample project for `BusIO` to show problem finding header file

### Changed
- Move repository from https://github.com/ianfixes/arduino_ci to https://github.com/Arduino-CI/arduino_ci
- Revise math macros to avoid name clashes
- `CppLibrary` functions returning C++ header or code files now respect the 1.0/1.5 library specification
- Mocks of built-in macros made more accurate
- NUM_SERIAL_PORTS can now be set explicitly
- Improve SPI header strategy

### Fixed
- Don't define `ostream& operator<<(nullptr_t)` if already defined by Apple
- `CppLibrary.in_tests_dir?` no longer produces an error if there is no tests directory
- The definition of the `_SFR_IO8` macro no longer produces errors about rvalues
- Typo in `cpp_library.rb`, misspelling of `aux_libraries`

### Deprecated
- `arduino_ci_remote.rb` CLI switch `--skip-compilation`
- Deprecated `arduino_ci_remote.rb` in favor of `arduino_ci.rb`

### Removed

### Security


## [0.3.0] - 2019-09-03
### Added
- Unit testing configuration now allows `exclude_dirs` to be set, which prevents stray source files from as part of unit testing allows


## [0.2.1] - 2019-08-12
### Added
- Minimal Wire mocks. Will not provide support for unit testing I2C communication yet, but will allow compilation of libraries that use I2C.
- `StreamTape` class now bridges `Stream` and `HardwareSerial` to allow general-purpose stream mocking & history

### Changed
- Arduino command failures (to read preferences) now causes a fatal error, with help for troubleshooting the underlying command

### Fixed
- Arduino library dependencies are now installed prior to unit testing, instead of prior to compilation testing.  Whoops.
- Arduino library dependencies with spaces in their names are now handled properly during compilation -- spaces are automatically coerced to underscores


## [0.2.0] - 2019-02-20
### Added
- `release-new-version.sh` script
- outputs for `PinHistory` can now report timestamps
- Fibonacci Clock for clock testing purposes (internal to this library)

### Changed
- Shortened `ArduinoQueue` push and pop operations
- `ci/Queue.h` is now `MockEventQueue.h`, with timing data
- `MockEventQueue::Node` now contains struct `MockEventQueue::Event`, which contains both the templated type `T` and a field for a timestamp.
- Construction of `MockEventQueue` now includes a constructor argument for the time-fetching function
- Construction of `PinHistory` now includes a constructor argument for the time-fetching function
- `PinHistory` can now return an array of timestamps for its events
- `GodmodeState` is now a singleton pattern, which is necessary to support the globality of Arduino functions
- `GodmodeState` now uses timestamped PinHistory for Analog and Digital

### Fixed
* `ArduinoQueue` no longer leaks memory


## [0.1.21] - 2019-02-07
### Added
- Proper `ostream operator <<` for `nullptr`
- Proper comparison operations fro `nullptr`

### Changed
- `Compare.h` heavily refactored to use a smallish macro

### Removed
- Homegrown implementation of `nullptr`

### Fixed
- `nullptr` support (again)


## [0.1.20] - 2019-01-31
### Fixed
- `unittest_setup()` and `unittest_teardown()` were not being executed for each unit test, only for the set of all tests.  My bad.


## [0.1.19] - 2019-01-30
### Added
- Added rspec sensitivity to the environment variable `$ARDUINO_CI_SELECT_CPP_TESTS=<glob>` (for `arduino_ci` gem hackers)
- `assertNotNull()` and `assureNotNull()` C++ comparisons

### Changed
- `CiConfig::allowable_unittest_files` now uses `Pathname` to full effect
- `nullptr` now defined in its own class

### Fixed
- Assertions on `nullptr`
- The defintion of `nullptr`


## [0.1.18] - 2019-01-29
### Added
- `ArduinoInstallation` and `ArduinoDownloader` now allow console output to optionally be set to an `IO` object of choice during `force_install`
- `ArduinoInstallation::force_install` now optionally accepts a version string
- `arduino_library_location.rb` script to print Arduino library location to stdout
- `arduino_ci_remote.rb` now supports `--skip-unittests` and `--skip-compilation`.  If you skip both, only the `autolocate!` of the Arduino binary will be performed.
- `keepachangelog_manager` gem to begin streamlining the release process
- `unittest_setup()` and `unittest_teardown()` macros, my thanks to @hlovdal for contributing this code
- Added rspec sensitivity to the environment variable `$ARDUINO_CI_SKIP_SPLASH_SCREEN_RSPEC_TESTS` (for `arduino_ci` gem hackers)
- Added rspec sensitivity to the environment variable `$ARDUINO_CI_SKIP_RUBY_RSPEC_TESTS` (for `arduino_ci` gem hackers)
- Added rspec sensitivity to the environment variable `$ARDUINO_CI_SKIP_CPP_RSPEC_TESTS` (for `arduino_ci` gem hackers)
- `nullptr` definition in C++
- `assertNull()` for unit tests

### Changed
- Unit tests and examples are now executed alphabetically by filename
- The `pgm_read_...` preprocessor macros in cpp/arduino/avr/pgmspace.h now expands to an expression with applicable type.
- Unit tests for interrupts (`attachInterrupt` and `detachInterrupt`) get their own file

### Fixed
- Library installation no longer "fails" if the library is already installed
- Platform definition for `mega2560` now includes proper AVR compiler flag
- `CppLibrary::vendor_bundle?` now asks where gems are, instead of assuming `vendor/bundle/`
- `install_local_library` step in `arduino_ci_remote.rb` now properly surfaces any error message


## [0.1.17] - 2019-01-14
### Added
- Provide an `itoa` function. It is present in Arduino's runtime environment but not on most (all?) host systems because itoa is not a portable standard function.
- `to_h` and `to_s` functions for `ci_config.rb`
- `CIConfig::clone`
- Ability to override `CIConfig` from a hash instead of just a file
- `arduino_ci_remote.rb` now supports command line switches `--testfile-select=GLOB` and `--testfile-reject=GLOB` (which can both be repeated)

### Changed
- Simplified the use of `Array.each` with a return statement; it's now simply `Array.find`
- `autolocate!` for Arduino installations now raises `ArduinoInstallationError` if `force_install` fails
- Errors due to missing YAML are now named `ConfigurationError`

### Fixed
- Determining a working OSX launch command no longer breaks on non-English installations
- `arduino_ci_remote.rb` now honors selected and rejected test files


## [0.1.16] - 2019-01-06
### Changed
- Finally put some factorization into the `arduino_ci_remote.rb` script: testing unit and testing compilation are now standalone functions

### Removed
- Unnecessary board changes during unit tests no longer happen

### Fixed
- Proper casting for `pgm_read_byte`


## [0.1.15] - 2019-01-04
### Added
- Checking for (empty) set of platforms to build now precedes the check for examples to build; this avoids assuming that all libraries will have an example and dumping the file set when none are found

### Fixed
- Spaces in the names of project directores no longer cause unit test binaries to fail execution
- Configuration file overrides with `nil`s (or empty arrays) now properly override their base configuration


## [0.1.14] - 2018-09-21
### Added
- Arduino command wrapper now natively supports board manager URLs
- `arduino_ci_remote.rb` checks for proper board manager URLs for requested platforms
- `arduino_ci_remote.rb` reports on Arduino executable location
- exposed `index_libraries` in `ArduinoCmd` so it can be used as an explicit build step

### Changed
- Centralized file listing code in `arduino_ci_remote.rb`
- `arduino_ci_remote.rb` is verbose about platforms, packages, and URLs

### Removed
- Linux wrapper no longer bails out on long-running commands.  That behavior was possible in Arduino 1.6.x that might pop up a graphical error message, but with the display manager removed this is no longer a concern


## [0.1.13] - 2018-09-19
### Changed
- `arduino_ci_remote.rb` now iterates over example platforms before examples (saves time)

### Fixed
- `arduino_ci_remote.rb` no longer crashes if `test/` directory doesn't exist


## [0.1.12] - 2018-09-13
### Added
- Explicit `libasan` checking (reporting) in build script

### Fixed
- Test file `int main(){}` needed a CPP extension in order to properly compile
- Fixed build script reporting for `inform()` when it returns a non-string value from its block
- Don't count false returns from `inform()` blocks as failures


## [0.1.11] - 2018-09-13
### Added
- Explicit checks that the requested test platforms are defined in YML
- Arduino command wrapper can now guess whether a library is installed
- CPP library class now reaches into included Arduino libraries for source files
- SPI mocks
- `ensure_arduino_installation.rb` to allow custom libraries to be installed
- Copy constructor for `ArduinoCITable`
- Some error information on failures to download the Arduino binary

### Changed
- Refactored documentation
- External libraries aren't forcibly installed via the Arduino binary (in `arduino_cmd_remote.rb`) if they appear to exist on disk already
- `attachInterrupt` and `detachInterrupt` are now mocked instead of `_NOP`
- Unit test binaries now run with debugging symbols and address sanitization (if available), to help isolate the causes of segfaults
- `ArduinoCommand::libdir` logic is now centralized, using `sketchbook.path` from prefs instead of hard-coding

### Removed
- Display Manager became no longer necessary with Arduino 1.8.X

### Fixed
- OSX splash screen re-disabled
- ArduinoCITable didn't initialize its size on `clear()`
- CPP file aggregation now ignores dotfiles
- Unit test `compilers` section of YAML configuration is now properly inherited from parent configuration files
- Retrieving preferences is now properly cached
- Paths on Windows should now work due to the use of `Pathname`
- symlinking directories in Windows environments now properly uses `/D` switch to `mklink`


## [0.1.10] - 2018-05-06
### Added
- Arduino `force_install` on Linux now attempts downloading 3 times and provides more information on failure
- Explicit check for `wget`
- Windows / Appveyor support, enabled largely by contributions from @tomduff
- `long long` support in `String`
- Representative `.gitignore` files in sample projects
- Cross-platform symlinking in `Host`
- OSX CI via Travis, with separate badges

### Changed
- Author
- Splash-screen-skip hack on OSX now falls back on "official" launch method if the hack doesn't work
- Refactored download/install code in prepration for windows CI
- Explicitly use 32-bit math for mocked Random()
- Ruby-centric download and unzipping of Arduino IDE packages, now with progress dots

### Removed
- `ArduinoDownloaderPosix` became empty, so it was removed

### Fixed
- `Gemfile.lock` files are properly ignored
- Windows hosts won't try to open a display manager
- `isnan` portability
- OSX force_install


## [0.1.9] - 2018-04-12
### Added
- Explicit tests of `.arduino-ci.yml` in `TestSomething` example

### Fixed
- Malformed YAML (duplicate unittests section) now has no duplicate section
- arduino_ci_remote.rb script now has correct arguments in build_for_test_with_configuration


## [0.1.8] - 2018-04-03
### Added
- Definition of `LED_BUILTIN`, first reported by `dfrencham` on GitHub
- Stubs for `tone` and `noTone`, first suggested by `dfrencham` on GitHub
- Ability to specify multiple compilers for unit testing

### Fixed
- Compile errors / portability issues in `WString.h` and `Print.h`, first reported by `dfrencham` on GitHub
- Compile errors / inheritance issues in `Print.h` and `Stream.h`, first reported by `dfrencham` on GitHub
- Print functions for int, double, long, etc


## [0.1.7] - 2018-03-07
### Changed
- Queue and Table are now ArduinoCIQueue and ArduinoCITable to avoid name collisions


## [0.1.6] - 2018-03-07
### Added
- `CppLibrary` can now report `gcc_version`

### Changed
- `arduino_ci_remote.rb` now formats tasks with multiple output lines more nicely
- Templates for CI classes are now pass-by-value (no const reference)

### Fixed
- Replaced pipes with `Open3.capture3` to avoid deadlocks when commands have too much output
- `ci_config.rb` now returns empty arrays (instead of nil) for undefined config keys
- `pgmspace.h` explictly includes `<string.h>`
- `__FlashStringHelper` should now be properly mocked for compilation
- `WString.h` bool operator now works and is simpler


## [0.1.5] - 2018-03-05
### Added
- Yaml files can have either `.yml` or `.yaml` extensions
- Yaml files support select/reject critera for paths of unit tests for targeted testing
- Pins now track history and can report it in Ascii (big- or little-endian) for digital sequences
- Pins now accept an array (or string) of input bits for providing pin values across multiple reads
- FlashStringHelper (and related macros) compilation mocks
- SoftwareSerial.  That took a while.
- Queue template implementation
- Table template implementation
- ObservableDataStream and DataStreamObserver pattern implementation
- DeviceUsingBytes and implementation of mocked serial device

### Changed
- Unit test executables print to STDERR just in case there are segfaults.  Uh, just in case I ever write any.

### Fixed
- OSX no longer experiences `javax.net.ssl.SSLKeyException: RSA premaster secret error` messages when downloading board package files
- `arduino_ci_remote.rb` no longer makes unnecessary changes to the board being tested
- Scripts no longer crash if there is no `test/` directory
- Scripts no longer crash if there is no `examples/` directory
- `assureTrue` and `assureFalse` now `assure` instead of just `assert`ing.


## [0.1.4] - 2018-02-01
### Added
- Support for all builtin Math functions https://www.arduino.cc/reference/en/
- Support for all builtin Bits and Bytes functions https://www.arduino.cc/reference/en/
- Support for GODMODE and time functions
- Support for Character functions https://www.arduino.cc/reference/en/
- Mocks for `random` functions with seed control
- Many original Arduino `#define`s
- Mocks for pinMode, analog/digital read/write
- Support for WString
- Support for Print
- Support for Stream (backed by a String implementation)
- All the IO stuff (pins, serial port support flags, etc) from the Arduino library
- Support for Serial (backed by GODMODE)

### Changed
- Made `wget` have quieter output


## [0.1.3] - 2018-01-25
### Added
- C++ functions for `assure`; `assert`s will run tests and continue, `assure`s will abort on failures
- Missing dotfiles in the `DoSomething` project have been committed

### Changed
- `arduino_ci_remote.rb` doesn't attempt to set URLs if nothing needs to be downloaded
- `arduino_ci_remote.rb` does unit tests first
- `unittest_main()` is now the macro for the `int main()` of test files

### Fixed
- All test files were reporting "not ok" in TAP output.  Now they are OK iff all asserts pass.
- Directories with a C++ extension in their name could cause problems.  Now they are ignored.
- `CppLibrary` had trouble with symlinks. It shoudn't anymore.
- `CppLibrary` had trouble with vendor bundles.  It might in the future, but I have a better fix ready to go if it's an issue.


## [0.1.2] - 2018-01-25
### Fixed
- Actually package CPP and YAML files into the gem.  Whoops.


## [0.1.1] - 2018-01-24
### Added
- README documentation for the actual unit tests


## [0.1.0] - 2018-01-24
### Added
- Unit testing support
- Documentation for all Ruby methods
- `ArduinoInstallation` class for managing lib / executable paths
- `DisplayManager` class for managing Xvfb instance if needed
- `ArduinoCmd` captures and caches preferences
- `ArduinoCmd` reports on whether a board is installed
- `ArduinoCmd` sets preferences
- `ArduinoCmd` installs boards
- `ArduinoCmd` installs libraries
- `ArduinoCmd` selects boards (compiler preference)
- `ArduinoCmd` verifies sketches
- `CppLibrary` manages GCC for unittests
- `CIConfig` manages overridable config for all testing

### Changed
- `DisplayManger.with_display` doesn't `disable` if the display was enabled prior to starting the block

### Fixed
- Built gems are `.gitignore`d
- Updated gems based on Github's security advisories


## [0.0.1] - 2018-01-10
### Added
- Skeleton for gem with working unit tests


[Unreleased]: https://github.com/Arduino-CI/arduino_ci/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/Arduino-CI/arduino_ci/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/Arduino-CI/arduino_ci/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.21...v0.2.0
[0.1.21]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.20...v0.1.21
[0.1.20]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.19...v0.1.20
[0.1.19]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.18...v0.1.19
[0.1.18]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.17...v0.1.18
[0.1.17]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.16...v0.1.17
[0.1.16]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.15...v0.1.16
[0.1.15]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.14...v0.1.15
[0.1.14]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.13...v0.1.14
[0.1.13]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.12...v0.1.13
[0.1.12]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.11...v0.1.12
[0.1.11]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.10...v0.1.11
[0.1.10]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.9...v0.1.10
[0.1.9]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.8...v0.1.9
[0.1.8]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.7...v0.1.8
[0.1.7]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/Arduino-CI/arduino_ci/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Arduino-CI/arduino_ci/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/Arduino-CI/arduino_ci/compare/v0.0.0...v0.0.1
