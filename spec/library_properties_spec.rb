require "spec_helper"

RSpec.describe ArduinoCI::LibraryProperties do

  context "property extraction" do
    library_properties = ArduinoCI::LibraryProperties.new(Pathname.new(__dir__) + "properties" + "example.library.properties")

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

    it "reads full_paragraph" do
      expect(library_properties.full_paragraph).to eq ([
        expected[:string][:sentence],
        expected[:string][:paragraph]
      ].join(" "))
    end

    it "doesn't crash on nonexistent fields" do
      expect(library_properties.dot_a_linkage).to be(nil)
    end

    it "converts to hash" do
      h = library_properties.to_h
      expect(h[:name].class).to eq(String)
      expect(h[:name]).to eq("WebServer")
      expect(h[:architectures].class).to eq(Array)
      expect(h[:architectures]).to contain_exactly("avr")
    end
  end

  context "Input handling" do
    malformed_examples = [
      "extra_blank_line.library.properties",
      "just_equals.library.properties",
      "no_equals.library.properties",
      "no_key.library.properties",
      "no_value.library.properties",
    ].map { |e| Pathname.new(__dir__) + "properties" + e }

    malformed_examples.each do |e|
      quirk = e.basename.to_s.split(".library.").first
      it "reads a properties file with #{quirk}" do
        expect { ArduinoCI::LibraryProperties.new(e) }.to_not raise_error
      end
    end
  end

end
