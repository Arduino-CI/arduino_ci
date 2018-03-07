#pragma once

#include "Table.h"
#include <WString.h>


// This pair of classes defines an Observer pattern for bits and bytes.
// This would allow us to create "devices" that respond in "real" time
// to Arduino outputs, in the form of altering the Arduino inputs
//
// e.g. replying to a serial output with serial input
class ObservableDataStream;

// datastream observers handle deliveries of bits and bytes.
// optionally, they can turn bit events into byte events with a given endianness
class DataStreamObserver {
  private:
    unsigned int  mBitPosition;   // for building the byte (mask helper)
    unsigned char mBuildingByte;  // for storing incoming bits
    bool          mAutoBitPack;   // whether to report the packed bits
    bool          mBigEndian;     // bit order for byte

  protected:
    // functions that are up to the implementer to provide.
    virtual void onBit(bool aBit) {}
    virtual void onByte(unsigned char aByte) {}
    virtual String observerName() const = 0;

  public:
    DataStreamObserver(bool autoBitPack, bool bigEndian)
    {
      mBitPosition = 0;
      mBuildingByte = 0x00;
      mAutoBitPack = autoBitPack;
      mBigEndian = bigEndian;
    }

    virtual ~DataStreamObserver()  {}

    // entry point for byte-related handler
    void handleByte(unsigned char aByte) {
      onByte(aByte);
    }

    // entry poitn for bit-related handler
    void handleBit(bool aBit) {
      onBit(aBit);

      if (!mAutoBitPack) return;

      // build the next value
      int shift = mBigEndian ? 7 - mBitPosition : mBitPosition;
      unsigned char val = aBit ? 0x1 : 0x0;
      mBuildingByte |= (val << shift);

      // if we roll over after incrementing, the byte is ready to ship
      mBitPosition = (mBitPosition + 1) % 8;
      if (mBitPosition == 0) {
        handleByte(mBuildingByte);
        mBuildingByte = 0x00;
      };
    }

    // inlined after ObservableDataStream definition to fake out the compiler
    bool attach(ObservableDataStream* source);
    bool detach(ObservableDataStream* source);
};

// Inheritable interface for things that produce data, like pins or serial ports
// this class allows others to subscribe for updates on these values and trigger actions
// e.g. if you "turn on" a motor with one pin and expect to see a change in an analog pin
class ObservableDataStream
{
  private:
    ArduinoCITable<String, DataStreamObserver*> mObservers;
    bool          mAdvertisingBit;
    unsigned char mAdvertisingByte;

  protected:
    // to allow both member and non-member functions to be called, we need to trick the compiler
    // into getting the (this) of a static function.  So the default is a work function signature
    // that takes a second optional argument.  in this case, we use the argument.

    static void workAdvertiseBit(ObservableDataStream* that, String _, DataStreamObserver* val) {
      val->handleBit(that->mAdvertisingBit);
    }

    static void workAdvertiseByte(ObservableDataStream* that, String _, DataStreamObserver* val) {
      val->handleByte(that->mAdvertisingByte);
    }

    // advertise functions allow the data stream to publish to observers

    // update all observers with a byte value
    void advertiseByte(unsigned char aByte) {
      // save the value to a class variable. then use the static method with this instance
      mAdvertisingByte = aByte;
      mObservers.iterate(workAdvertiseByte, this);
    }

    // update all observers with a byte value
    // build up a byte
    // if requested, advertise the byte
    void advertiseBit(bool aBit) {
      // do the named thing first, of course
      mAdvertisingBit = aBit;
      mObservers.iterate(workAdvertiseBit, this);
    }

  public:
    ObservableDataStream() : mObservers() {
      mAdvertisingBit  = false; // we'll re-init on demand though
      mAdvertisingByte = 0x07;  // we'll re-init on demand though
    }

    virtual ~ObservableDataStream() {}

    bool addObserver(String name, DataStreamObserver* obs) { return mObservers.add(name, obs); }
    bool removeObserver(String name) { return mObservers.remove(name); }
};

inline bool DataStreamObserver::attach(ObservableDataStream* source) { return source->addObserver(observerName(), this); }

inline bool DataStreamObserver::detach(ObservableDataStream* source) { return source->removeObserver(observerName()); }
