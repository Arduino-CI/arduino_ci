# ARDUINO_CI should point to cpp/ and be provided as a shell environment variable
LIBRARIES := $(shell bundle exec arduino_library_location.rb)
SRC=$(LIBRARIES)/Makefile/src
TEST=$(LIBRARIES)/Makefile/test
BIN=$(LIBRARIES)/Makefile/.arduino_ci

FLAGS=-std=c++0x \
	-Wno-deprecated-declarations \
  -DARDUINO=100 \
  -g \
  -O1 \
  -fno-omit-frame-pointer \
  -fno-optimize-sibling-calls \
  -fsanitize=address \
  -Wno-unknown-attributes \
  -Wno-address-of-packed-member \
  -D__AVR__ \
  -D__AVR_ATmega2560__ \
  -DARDUINO_ARCH_AVR \
  -DARDUINO_AVR_MEGA2560

INCLUDE=-I$(ARDUINO_CI)/arduino \
  -I$(ARDUINO_CI)/unittest \
  -I$(LIBRARIES)/Makefile/src \

GPP_TEST=g++ -fPIC $(FLAGS) -L$(BIN) $(INCLUDE)

.PHONY : all
all : $(BIN)/test.cpp.bin


$(BIN)/test.cpp.bin: $(BIN)/libarduino.so $(TEST)/test.cpp
	$(GPP_TEST) -o $(BIN)/test.cpp.bin $(TEST)/test.cpp -larduino

OBJECTS=$(BIN)/stdlib.o $(BIN)/Godmode.o $(BIN)/Arduino.o $(BIN)/ArduinoUnitTests.o \
	$(BIN)/SharedLibrary.o 

$(BIN)/libarduino.so: $(OBJECTS)
	g++ $(FLAGS) -shared -fPIC -Wl,-undefined,dynamic_lookup -L$(BIN) $(INCLUDE) \
	-o $(BIN)/libarduino.so $(OBJECTS)

$(BIN)/stdlib.o: $(ARDUINO_CI)/arduino/stdlib.cpp
	g++ -c $(FLAGS) $(INCLUDE) -o $(BIN)/stdlib.o $(ARDUINO_CI)/arduino/stdlib.cpp

$(BIN)/Godmode.o: $(ARDUINO_CI)/arduino/Godmode.cpp
	g++ -c $(FLAGS) $(INCLUDE) -o $(BIN)/Godmode.o $(ARDUINO_CI)/arduino/Godmode.cpp

$(BIN)/Arduino.o: $(ARDUINO_CI)/arduino/Arduino.cpp
	g++ -c $(FLAGS) $(INCLUDE) -o $(BIN)/Arduino.o $(ARDUINO_CI)/arduino/Arduino.cpp

$(BIN)/ArduinoUnitTests.o: $(ARDUINO_CI)/unittest/ArduinoUnitTests.cpp
	g++ -c $(FLAGS) $(INCLUDE) -o $(BIN)/ArduinoUnitTests.o $(ARDUINO_CI)/unittest/ArduinoUnitTests.cpp

$(BIN)/SharedLibrary.o: $(SRC)/SharedLibrary.cpp
	g++ -c $(FLAGS) $(INCLUDE) -o $(BIN)/SharedLibrary.o $(SRC)/SharedLibrary.cpp


.PHONY: clean
clean:
	rm -rf $(BIN)/*
