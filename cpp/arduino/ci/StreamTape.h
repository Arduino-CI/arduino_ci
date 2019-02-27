#pragma once

#include "../Stream.h"

/**
 * Stream with godmode-controlled input and godmode-persisted output
 */
class StreamTape : public Stream, public ObservableDataStream
{
  protected:
    String* mGodmodeDataOut;
    // mGodmodeDataIn is provided by Stream

  public:
    StreamTape(String* dataIn, String* dataOut, unsigned long* delay): Stream(), ObservableDataStream() {
      mGodmodeDataIn      = dataIn;
      mGodmodeDataOut     = dataOut;
      mGodmodeMicrosDelay = delay;
    }

    // virtual int available(void);
    // virtual int peek(void);
    // virtual int read(void);
    // virtual int availableForWrite(void);
    // virtual void flush(void);
    virtual size_t write(uint8_t aChar) {
      mGodmodeDataOut->append(String((char)aChar));
      advertiseByte((unsigned char)aChar);
      return 1;
    }

    // https://stackoverflow.com/a/4271276
    using Print::write; // pull in write(str) and write(buf, size) from Print

};

