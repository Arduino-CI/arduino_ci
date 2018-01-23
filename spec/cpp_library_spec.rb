require "spec_helper"

sampleproj_path = File.join(File.dirname(File.dirname(__FILE__)), "SampleProjects")

RSpec.describe ArduinoCI::CppLibrary do
  cpp_lib_path = File.join(sampleproj_path, "DoSomething")
  cpp_library = ArduinoCI::CppLibrary.new(cpp_lib_path)
  context "cpp_files" do
    it "finds cpp files in directory" do
      dosomething_cpp_files = ["DoSomething/do-something.cpp"]
      relative_paths = cpp_library.cpp_files.map { |f| f.split("SampleProjects/", 2)[1] }
      expect(relative_paths).to match_array(dosomething_cpp_files)
    end
  end

  context "header_dirs" do
    it "finds directories containing h files" do
      dosomething_header_dirs = ["DoSomething"]
      relative_paths = cpp_library.header_dirs.map { |f| f.split("SampleProjects/", 2)[1] }
      expect(relative_paths).to match_array(dosomething_header_dirs)
    end
  end

  context "build" do
    arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!
    it "builds libraries" do
      expect(cpp_library.build(arduino_cmd)).to be true
    end
  end

end
