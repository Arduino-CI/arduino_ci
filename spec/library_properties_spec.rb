require "spec_helper"

RSpec.describe ArduinoCI::LibraryProperties do

  context "property extraction" do
    library_properties = ArduinoCI::LibraryProperties.new(Pathname.new(__dir__) + "properties/example.library.properties")

    expected = {
      string: {
        name: "WebServer",
        version: "1.0.0",
        maintainer: "Cristian Maglie <c.maglie@example.com>",
        sentence: "A library that makes coding a Webserver a breeze.",
        paragraph: "Supports HTTP1.1 and you can do GET and POST.",
        category: "Communication",
        url: "http://example.com/",
      },

      bool: {
        precompiled: true
      },

      csv: {
        author: ["Cristian Maglie <c.maglie@example.com>", "Pippo Pluto <pippo@example.com>"],
        architectures: ["avr"],
        includes: ["WebServer.h"],
        depends: ["ArduinoHttpClient"],
      },
    }.freeze

    expected.each do |atype, values|
      values.each do |meth, val|
        it "reads #{atype} field #{meth}" do
          expect(library_properties.send(meth)).to eq(val)
        end
      end
    end

    it "doesn't crash on nonexistent fields" do
      expect(library_properties.dot_a_linkage).to be(nil)
    end
  end


end
