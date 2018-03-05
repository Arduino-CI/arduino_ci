#include <Arduino.h>
#include <ArduinoUnitTests.h>
#include <ci/ObservableDataStream.h>

class Source : public ObservableDataStream {
  public:
    Source() : ObservableDataStream() {}

    // expose protected functions
    void doBit(bool val) { advertiseBit(val); }
    void doByte(unsigned char val) { advertiseByte(val); }
};

class Sink : public DataStreamObserver {
  public:
    bool lastBit;
    unsigned char lastByte;

    Sink() : DataStreamObserver(false, false) {}

    virtual String observerName() const { return "Sink"; }
    virtual void onBit(bool val) { lastBit = val; }
    virtual void onByte(unsigned char val) { lastByte = val; }
};

class BitpackSink : public DataStreamObserver {
  public:
    bool lastBit;
    unsigned char lastByte;

    BitpackSink() : DataStreamObserver(true, true) {}

    virtual String observerName() const { return "BitpackSink"; }
    virtual void onBit(bool val) { lastBit = val; }
    virtual void onByte(unsigned char val) { lastByte = val; }
};

unittest(attach_sink_to_src)
{
  Source src = Source();
  Sink dst = Sink();

  dst.lastByte = 'z';
  src.addObserver("foo", &dst);
  src.doByte('a');
  assertEqual('a', dst.lastByte);
  src.removeObserver("foo");
  src.doByte('b');
  assertEqual('a', dst.lastByte);
}

unittest(attach_src_to_sink)
{
  Source src = Source();
  Sink dst = Sink();

  dst.attach(&src);
  src.doByte('f');
  assertEqual('f', dst.lastByte);
}

// 01010100 T if bigendian
unittest(bitpack)
{
  Source src = Source();
  Sink dst = Sink();
  BitpackSink bst = BitpackSink();

  bool message[8] = {0, 1, 0, 1, 0, 1, 0, 0};

  bst.lastByte = 'f';
  dst.lastByte = 'f';
  bst.attach(&src);
  dst.attach(&src);

  for (int i = 0; i < 8; ++i) {
    src.doBit(message[i]);
    assertEqual(message[i], bst.lastBit);
    assertEqual(message[i], dst.lastBit);
  }

  assertEqual('f', dst.lastByte);    // not doing bitpacking
  assertEqual('T', bst.lastByte);    // should have formed a binary T char by now
  assertNotEqual('*', bst.lastByte); // backwards endianness
}

// 01010100 T if bigendian
unittest(from_pinhistory)
{
  GodmodeState* state = GODMODE();
  state->reset();

  BitpackSink bst = BitpackSink();
  bst.attach(&state->digitalPin[2]);
  bst.lastByte = 'f';

  bool message[8] = {0, 1, 0, 1, 0, 1, 0, 0};
  for (int i = 0; i < 8; ++i) {
    digitalWrite(2, message[i]);
    assertEqual(message[i], bst.lastBit);
  }

  assertEqual('T', bst.lastByte);    // should have formed a binary T char by now
  assertNotEqual('*', bst.lastByte); // backwards endianness
}

unittest_main()
