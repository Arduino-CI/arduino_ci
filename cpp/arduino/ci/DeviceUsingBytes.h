#pragma once

#include "ObservableDataStream.h"
#include "Table.h"
#include <WString.h>
#include <Godmode.h>


// Define a rudimentary serial device that responds to byte sequences
//
// The class monitors whatever stream it is observing, and builds up
//  a buffer of the incoming data.  If/when that data matches one of
//  the stored responses, the buffer is cleared and the response to
//  the matched requests is sent to the handler `onMatchInput`
//
//  WARNING: if input is consumed and no matches are found, you are
//    in a bad state where you can never match anything again.  @TODO
//
// The extender of this abstract class should provide the following:
//   1. A set of responses using one of the provided convenience functions:
//      * `addResponse`: request and response are taken verbatim
//      * `addResponseLine`: request and response are appended a \n
//      * `addResponseCRLF`: request and response are appended a \r\n
//   2. An action `onMatchInput` -- what to do with a response when triggered
class DeviceUsingBytes : public DataStreamObserver {
  public:
    String mMessage;
    ArduinoCITable<String, String> mResponses;
    GodmodeState* state;


    DeviceUsingBytes() : DataStreamObserver(true, false) {
      mMessage = "";
      state = GODMODE();
    }

    virtual ~DeviceUsingBytes() {}

    bool addResponse(String hear, String say) { return mResponses.add(hear, say); }
    bool addResponseLine(String hear, String say) { return mResponses.add(hear + "\n", say + "\n"); }
    bool addResponseCRLF(String hear, String say) { return mResponses.add(hear + "\r\n", say + "\r\n"); }

    // what to do when there is a match
    virtual void onMatchInput(String output) = 0;

    virtual String observerName() const { return "DeviceUsingBytes"; }

    virtual void onByte(unsigned char c) {
      mMessage.concat(c);
      if (mResponses.has(mMessage)) {
        onMatchInput(mResponses.get(mMessage));
        mMessage = "";
      }
    }
};

