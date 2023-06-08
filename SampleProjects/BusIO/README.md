# BusIO

This is an example of a library that depends on Adafruit BusIO.
It is provided to help reproduce #192 and #352.

This example specifies a dependency in `library.properties`, which
exercises the `arduino_ci.rb` CI runner in a way that the other
SampleProjects currently do not.
