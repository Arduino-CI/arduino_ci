#include "ArduinoUnitTests.h"

Test* Test::sRoot = 0;
Test* Test::sCurrent = 0;
int Test::mAssertCounter = 0;
int Test::mTestCounter = 0;
