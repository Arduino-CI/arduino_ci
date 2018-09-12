require "spec_helper"
require "pathname"

sampleproj_path = Pathname.new(__dir__).parent + "SampleProjects"

def get_relative_dir(sampleprojects_tests_dir)
  base_dir = sampleprojects_tests_dir.ascend do |path|
    break path if path.split[1].to_s == "SampleProjects"
  end
  sampleprojects_tests_dir.relative_path_from(base_dir)
end

RSpec.describe ArduinoCI::CppLibrary do
  cpp_lib_path = sampleproj_path + "DoSomething"
  cpp_library = ArduinoCI::CppLibrary.new(cpp_lib_path, Pathname.new("my_fake_arduino_lib_dir"))
  context "cpp_files" do
    it "finds cpp files in directory" do
      dosomething_cpp_files = [Pathname.new("DoSomething") + "do-something.cpp"]
      relative_paths = cpp_library.cpp_files.map { |f| get_relative_dir(f) }
      expect(relative_paths).to match_array(dosomething_cpp_files)
    end
  end

  context "header_dirs" do
    it "finds directories containing h files" do
      dosomething_header_dirs = [Pathname.new("DoSomething")]
      relative_paths = cpp_library.header_dirs.map { |f| get_relative_dir(f) }
      expect(relative_paths).to match_array(dosomething_header_dirs)
    end
  end

  context "tests_dir" do
    it "locates the tests directory" do
      # since we don't know where the CI system will install this stuff,
      # we need to go looking for a relative path to the SampleProjects directory
      # just to get our "expected" value
      relative_path = get_relative_dir(cpp_library.tests_dir)
      expect(relative_path.to_s).to eq("DoSomething/test")
    end
  end

  context "test_files" do
    it "finds cpp files in directory" do
      dosomething_test_files = [
        "DoSomething/test/good-null.cpp",
        "DoSomething/test/good-library.cpp",
        "DoSomething/test/bad-null.cpp",
      ].map { |f| Pathname.new(f) }
      relative_paths = cpp_library.test_files.map { |f| get_relative_dir(f) }
      expect(relative_paths).to match_array(dosomething_test_files)
    end
  end

  context "test" do
    config = ArduinoCI::CIConfig.default

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
      expected = path.basename.to_s.include?("good")
      config.compilers_to_use.each do |compiler|
        it "tests #{File.basename(path)} with #{compiler} expecting #{expected}" do
          exe = cpp_library.build_for_test_with_configuration(path, [], compiler, config.gcc_config("uno"))
          expect(exe).not_to be nil
          expect(cpp_library.run_test_file(exe)).to eq(expected)
        end
      end
    end
  end

end
