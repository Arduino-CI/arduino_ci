require "spec_helper"

sampleproj_path = File.join(File.dirname(File.dirname(__FILE__)), "SampleProjects")

RSpec.describe "TestSomething C++" do
  cpp_lib_path = File.join(sampleproj_path, "TestSomething")
  cpp_library = ArduinoCI::CppLibrary.new(cpp_lib_path, "my_fake_arduino_lib_dir")
  context "cpp_files" do
    it "finds cpp files in directory" do
      testsomething_cpp_files = ["TestSomething/test-something.cpp"]
      relative_paths = cpp_library.cpp_files.map { |f| f.split("SampleProjects/", 2)[1] }
      expect(relative_paths).to match_array(testsomething_cpp_files)
    end
  end
  config = ArduinoCI::CIConfig.default.from_example(cpp_lib_path)

  context "unit tests" do

    it "is going to test more than one library" do
      test_files = cpp_library.test_files
      expect(test_files.empty?).to be false
    end

    it "has some allowable test files" do
      allowed_files = config.allowable_unittest_files(cpp_library.test_files)
      expect(allowed_files.empty?).to be false
    end

    it "has at least one compiler defined" do
      expect(config.compilers_to_use.length.zero?).to be(false)
    end

    it "has at least one unit test platform defined" do
      expect(config.platforms_to_unittest.length.zero?).to be(false)
    end

    test_files = config.allowable_unittest_files(cpp_library.test_files)
    test_files.each do |path|
      tfn = File.basename(path)

      config.compilers_to_use.each do |compiler|

        context "file #{tfn} (using #{compiler})" do

          before(:all) do
            @exe = cpp_library.build_for_test_with_configuration(path, [], compiler, config.gcc_config("uno"))
          end

          # extra debug for c++ failures
          after(:each) do |example|
            if example.exception
              puts "Last command: #{cpp_library.last_cmd}"
              puts "========== Stdout:"
              puts cpp_library.last_out
              puts "========== Stderr:"
              puts cpp_library.last_err
            end
          end

          it "#{tfn} builds successfully" do
            expect(@exe).not_to be nil
          end
          it "#{tfn} passes tests" do
            skip "Can't run the test program because it failed to build" if @exe.nil?
            expect(cpp_library.run_test_file(@exe)).to_not be_falsey
          end
        end
      end
    end
  end
end
