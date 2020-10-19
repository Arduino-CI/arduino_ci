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
  next if skip_ruby_tests

  answers = {
    "DoSomething": {
      one_five: false,
      cpp_files: [Pathname.new("DoSomething") + "do-something.cpp"],
      header_dirs: [Pathname.new("DoSomething")],
      test_files: [
        "DoSomething/test/good-null.cpp",
        "DoSomething/test/good-library.cpp",
        "DoSomething/test/bad-null.cpp",
      ].map { |f| Pathname.new(f) }
    },
    "OnePointOhDummy": {
      one_five: false,
      cpp_files: [
        "OnePointOhDummy/YesBase.cpp",
        "OnePointOhDummy/utility/YesUtil.cpp",
      ].map { |f| Pathname.new(f) },
      header_dirs: [
        "OnePointOhDummy",
        "OnePointOhDummy/utility"
      ].map { |f| Pathname.new(f) },
      test_files: []
    },
    "OnePointFiveMalformed": {
      one_five: false,
      cpp_files: [
        "OnePointFiveMalformed/YesBase.cpp",
        "OnePointFiveMalformed/utility/YesUtil.cpp",
      ].map { |f| Pathname.new(f) },
      header_dirs: [
        "OnePointFiveMalformed",
        "OnePointFiveMalformed/utility"
      ].map { |f| Pathname.new(f) },
      test_files: []
    },
    "OnePointFiveDummy": {
      one_five: true,
      cpp_files: [
        "OnePointFiveDummy/src/YesSrc.cpp",
        "OnePointFiveDummy/src/subdir/YesSubdir.cpp",
      ].map { |f| Pathname.new(f) },
      header_dirs: [
        "OnePointFiveDummy/src",
        "OnePointFiveDummy/src/subdir",
      ].map { |f| Pathname.new(f) },
      test_files: []
    }
  }.freeze

  answers.each do |sampleproject, expected|
    context "#{sampleproject}" do
      cpp_lib_path = sampleproj_path + sampleproject.to_s
      cpp_library = ArduinoCI::CppLibrary.new(cpp_lib_path, Pathname.new("my_fake_arduino_lib_dir"), [])

      it "detects 1.5 format" do
        expect(cpp_library.one_point_five?).to eq(expected[:one_five])
      end

      context "cpp_files" do
        it "finds cpp files in directory" do
          relative_paths = cpp_library.cpp_files.map { |f| get_relative_dir(f) }
          expect(relative_paths.map(&:to_s)).to match_array(expected[:cpp_files].map(&:to_s))
        end
      end

      context "header_dirs" do
        it "finds directories containing h files" do
          relative_paths = cpp_library.header_dirs.map { |f| get_relative_dir(f) }
          expect(relative_paths.map(&:to_s)).to match_array(expected[:header_dirs].map(&:to_s))
        end
      end

      context "tests_dir" do
        it "locates the tests directory" do
          # since we don't know where the CI system will install this stuff,
          # we need to go looking for a relative path to the SampleProjects directory
          # just to get our "expected" value
          relative_path = get_relative_dir(cpp_library.tests_dir)
          expect(relative_path.to_s).to eq("#{sampleproject}/test")
        end
      end

      context "test_files" do
        it "finds cpp files in directory" do
          relative_paths = cpp_library.test_files.map { |f| get_relative_dir(f) }
          expect(relative_paths.map(&:to_s)).to match_array(expected[:test_files].map(&:to_s))
        end
      end
    end
  end

  context "test" do
    cpp_lib_path = sampleproj_path + "DoSomething"
    cpp_library = ArduinoCI::CppLibrary.new(cpp_lib_path, Pathname.new("my_fake_arduino_lib_dir"), [])
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
