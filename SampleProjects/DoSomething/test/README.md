## Purpose

These files are designed to test the testing framework (the Ruby gem) itself, library installation and compilation. (Feature tests for C++ unittest/arduino code belong in `../TestSomething/test/`.)

## Naming convention

Files in this directory are given names that either contains "bad" (if it is expected to fail) or "good" (if it is expected to pass).  This provides a signal to `rspec` for how the code is expected to perform (see `spec/cpp_library_spec.rb`).

When writing your own tests you should not follow this ("bad" and "good") naming convention. You should write all your tests expecting them to pass (relying on this `DoSomething` test to ensure that failures are actually noticed!).
