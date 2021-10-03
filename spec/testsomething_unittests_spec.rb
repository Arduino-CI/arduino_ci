require "spec_helper"
require "pathname"

require 'fake_lib_dir'

sampleproj_path = Pathname.new(__dir__).parent + "SampleProjects"

RSpec.describe "TestSomething C++" do
  next if skip_cpp_tests

  # we will need to install some dummy libraries into a fake location, so do that on demand
  fld = FakeLibDir.new
  backend = fld.backend
  test_lib_name = "TestSomething"
  cpp_lib_path = sampleproj_path + test_lib_name

  context "cpp_files" do
    around(:example) { |example| fld.in_pristine_fake_libraries_dir(example) }
    before(:each) do
      @base_dir = fld.libraries_dir
      @cpp_library = backend.install_local_library(cpp_lib_path)
    end

    it "finds cpp files in directory" do
      testsomething_cpp_files = [Pathname.new("TestSomething/src/test-something.cpp")]
      relative_paths = @cpp_library.cpp_files.map { |f| f.relative_path_from(@base_dir) }
      expect(relative_paths).to match_array(testsomething_cpp_files)
    end
  end
  config = ArduinoCI::CIConfig.default.from_example(cpp_lib_path)

  context "unit tests" do
    around(:example) { |example| fld.in_pristine_fake_libraries_dir(example) }
    before(:each) do
      @base_dir = fld.libraries_dir
      @cpp_library = backend.install_local_library(cpp_lib_path)
    end

    it "is going to test more than one library" do
      test_files = @cpp_library.test_files
      expect(test_files.empty?).to be false
    end

    it "has some allowable test files" do
      allowed_files = config.allowable_unittest_files(@cpp_library.test_files)
      expect(allowed_files.empty?).to be false
    end

    it "has at least one compiler defined" do
      expect(config.compilers_to_use.length.zero?).to be(false)
    end

    it "has at least one unit test platform defined" do
      expect(config.platforms_to_unittest.length.zero?).to be(false)
    end

    cpp_library = backend.install_local_library(cpp_lib_path)
    test_files = config.allowable_unittest_files(cpp_library.test_files)

    # filter the list based on a glob, if provided
    unless ENV["ARDUINO_CI_SELECT_CPP_TESTS"].nil?
      Dir.chdir(@cpp_library.tests_dir) do
        globbed = Pathname.glob(ENV["ARDUINO_CI_SELECT_CPP_TESTS"])
        test_files.select! { |p| globbed.include?(p.basename) }
      end
    end
    test_files.each do |path|
      tfn = File.basename(path)

      config.compilers_to_use.each do |compiler|

        context "file #{tfn} (using #{compiler})" do
          around(:example) { |example| fld.in_pristine_fake_libraries_dir(example) }

          before(:each) do
            @cpp_library = backend.install_local_library(cpp_lib_path)
            @exe = @cpp_library.build_for_test_with_configuration(path, [], compiler, config.gcc_config("uno"))
          end

          # extra debug for c++ failures
          after(:each) do |example|
            if example.exception
              puts "Last command: #{@cpp_library.last_cmd}"
              puts "========== Stdout:"
              puts @cpp_library.last_out
              puts "========== Stderr:"
              puts @cpp_library.last_err
            end
          end

          it "#{tfn} builds successfully" do
            expect(@exe).not_to be nil
          end
          it "#{tfn} passes tests" do
            skip "Can't run the test program because it failed to build" if @exe.nil?
            expect(@cpp_library.run_test_file(@exe)).to_not be_falsey
          end
        end
      end
    end
  end
end
