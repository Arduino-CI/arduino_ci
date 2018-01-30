require "spec_helper"

sampleproj_path = File.join(File.dirname(File.dirname(__FILE__)), "SampleProjects")

RSpec.describe ArduinoCI::CppLibrary do
  cpp_lib_path = File.join(sampleproj_path, "TestSomething")
  cpp_library = ArduinoCI::CppLibrary.new(cpp_lib_path)
  context "cpp_files" do
    it "finds cpp files in directory" do
      testsomething_cpp_files = ["TestSomething/test-something.cpp"]
      relative_paths = cpp_library.cpp_files.map { |f| f.split("SampleProjects/", 2)[1] }
      expect(relative_paths).to match_array(testsomething_cpp_files)
    end
  end

  context "header_dirs" do
    it "finds directories containing h files" do
      testsomething_header_dirs = ["TestSomething"]
      relative_paths = cpp_library.header_dirs.map { |f| f.split("SampleProjects/", 2)[1] }
      expect(relative_paths).to match_array(testsomething_header_dirs)
    end
  end

  context "tests_dir" do
    it "locate the tests directory" do
      testsomething_header_dirs = ["TestSomething"]
      relative_path = cpp_library.tests_dir.split("SampleProjects/", 2)[1]
      expect(relative_path).to eq("TestSomething/test")
    end
  end

  context "test_files" do
    it "finds cpp files in directory" do
      testsomething_test_files = [
        "TestSomething/test/good-null.cpp",
        "TestSomething/test/good-math.cpp",
        "TestSomething/test/good-trig.cpp",
        "TestSomething/test/good-library.cpp",
        "TestSomething/test/good-godmode.cpp",
        "TestSomething/test/good-defines.cpp",
        "TestSomething/test/good-wcharacter.cpp",
        "TestSomething/test/good-wstring.cpp",
        "TestSomething/test/bad-null.cpp",
      ]
      relative_paths = cpp_library.test_files.map { |f| f.split("SampleProjects/", 2)[1] }
      expect(relative_paths).to match_array(testsomething_test_files)
    end
  end

  context "test" do
    after(:each) do |example|
      if example.exception
        puts "Last command: #{cpp_library.last_cmd}"
        puts "========== Stdout:"
        puts cpp_library.last_out
        puts "========== Stderr:"
        puts cpp_library.last_err
      end
    end

    it "is going to test more than one library" do
      test_files = cpp_library.test_files
      expect(test_files.empty?).to be false
    end

    test_files = cpp_library.test_files
    test_files.each do |path|
      expected = path.include?("good")
      it "tests #{File.basename(path)} expecting #{expected}" do
        exe = cpp_library.build_for_test_with_configuration(path, [], nil)
        expect(exe).not_to be nil
        expect(cpp_library.run_test_file(exe)).to eq(expected)
      end
    end
  end

end
