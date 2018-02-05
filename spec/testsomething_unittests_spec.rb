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

    # well this override is clunky as hell.
    # @todo smooth this out for external purposes
    ArduinoCI::CIConfig.default.with_config(cpp_lib_path, ArduinoCI::CIConfig.default) do |config_path|
      config = ArduinoCI::CIConfig.default.with_override(config_path)

      test_files = config.allowable_unittest_files(cpp_library.test_files)
      test_files.each do |path|
        expected = path.include?("good")
        it "tests #{File.basename(path)} expecting #{expected}" do
          exe = cpp_library.build_for_test_with_configuration(path, [], config.gcc_config("uno"))
          expect(exe).not_to be nil
          expect(cpp_library.run_test_file(exe)).to eq(expected)
        end
      end
    end
  end
end
