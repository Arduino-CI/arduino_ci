# Purpose

These files are designed to test the Ruby gem itself, such that its basic tasks of library installation and compilation can be verified.  (i.e., use minimal C++ files -- feature tests for C++ unittest/arduino code belong in `../TestSomething/test/`).

## Naming convention

Files in this directory are expected to have names that either contains "bad" if it is expected to fail or "good" if it is expected to pass.  This provides a signal to `rspec` for how the code is expected to perform.
