# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- `ArduinoInstallation` class for managing lib / executable paths
- `DisplayManager` class for managing Xvfb instance if needed
- `ArduinoCmd` can report on whether a board is installed

### Changed
- `DisplayManger.with_display` doesn't `disable` if the display was enabled prior to starting the block

### Deprecated

### Removed

### Fixed
- Built gems are `.gitignore`d
- Updated gems based on Github's security advisories

### Security


## [0.0.1] - 2018-01-10
### Added
- Skeleton for gem with working unit tests


[Unreleased]: https://github.com/ifreecarve/arduino_ci/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/ifreecarve/arduino_ci/compare/v0.0.0...v0.0.1
