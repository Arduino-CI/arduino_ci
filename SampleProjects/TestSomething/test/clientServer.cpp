#include <Arduino.h>
#include <ArduinoUnitTests.h>
#include <Client.h>
#include <IPAddress.h>
#include <Printable.h>
#include <Server.h>
#include <Udp.h>

// Provide some rudamentary tests for these classes
// They get more thoroughly tested in SampleProjects/NetworkLib

unittest(Client) {
  Client client;
  assertEqual(0, client.available());         // subclass of Stream
  assertEqual(0, client.availableForWrite()); // subclass of Print
  String outData = "Hello, world!";
  client.println(outData);
  String inData = client.readString();
  assertEqual(outData + "\r\n", inData);
}

unittest(IPAddress) {
  IPAddress ipAddress0;
  assertEqual(0, ipAddress0.asWord());
  uint32_t one = 0x01020304;
  IPAddress ipAddress1(one);
  assertEqual(one, ipAddress1.asWord());
  IPAddress ipAddress2(2, 3, 4, 5);
  assertEqual(0x05040302, ipAddress2.asWord());
  uint8_t bytes[] = {3, 4, 5, 6};
  IPAddress ipAddress3(bytes);
  assertEqual(0x06050403, ipAddress3.asWord());
  uint8_t *pBytes = ipAddress1.raw_address();
  assertEqual(*(pBytes + 0), 4);
  assertEqual(*(pBytes + 1), 3);
  assertEqual(*(pBytes + 2), 2);
  assertEqual(*(pBytes + 3), 1);
  IPAddress ipAddress1a(one);
  assertTrue(ipAddress1 == ipAddress1a);
  assertTrue(ipAddress1 != ipAddress2);
  assertEqual(1, ipAddress1[3]);
  ipAddress1[1] = 11;
  assertEqual(11, ipAddress1[1]);
  assertEqual(1, ipAddress0 + 1);
}

class TestPrintable : public Printable {
public:
  virtual size_t printTo(Print &p) const {
    p.print("TestPrintable");
    return 13;
  }
};

unittest(Printable) {
  TestPrintable printable;
  Client client;
  client.print(printable);
  assertEqual("TestPrintable", client.readString());
}

class TestServer : public Server {
public:
  uint8_t data;
  virtual size_t write(uint8_t value) { data = value; };
};

unittest(Server) {
  TestServer server;
  server.write(67);
  assertEqual(67, server.data);
}

unittest(Udp) {
  UDP udp;
  assertEqual(0, udp.available());         // subclass of Stream
  assertEqual(0, udp.availableForWrite()); // subclass of Print
  String outData = "Hello, world!";
  udp.println(outData);
  String inData = udp.readString();
  assertEqual(outData + "\r\n", inData);
}

unittest_main()
