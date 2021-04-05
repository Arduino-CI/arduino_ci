require "spec_helper"
require "pathname"
require 'tmpdir'

require 'fake_lib_dir'

sampleproj_path = Pathname.new(__dir__).parent + "SampleProjects"

def verified_install(backend, path)
  ret = backend.install_local_library(path)
  raise "backend.install_local_library from '#{path}' failed: #{backend.last_msg}" if ret.nil?
  ret
end

RSpec.describe "ExcludeSomething C++" do
  next if skip_cpp_tests

  # we will need to install some dummy libraries into a fake location, so do that on demand
  fld = FakeLibDir.new
  backend = fld.backend
  test_lib_name = "ExcludeSomething"
  cpp_lib_path = sampleproj_path + test_lib_name
  around(:example) { |example| fld.in_pristine_fake_libraries_dir(example) }
  before(:each) do
    @base_dir = fld.libraries_dir
    @cpp_library = verified_install(backend, cpp_lib_path)
  end

  context "without excludes" do
    context "cpp_files" do
      it "finds cpp files in directory" do
        expect(@cpp_library).to_not be(nil)
        excludesomething_cpp_files = [
          Pathname.new("ExcludeSomething/src/exclude-something.cpp"),
          Pathname.new("ExcludeSomething/src/excludeThis/exclude-this.cpp")
        ]
        relative_paths = @cpp_library.cpp_files.map { |f| f.relative_path_from(@base_dir) }
        expect(relative_paths).to match_array(excludesomething_cpp_files)
      end
    end

    context "unit tests" do
      it "can't build due to files that should have been excluded" do
        @cpp_library = verified_install(backend, cpp_lib_path)
        config       = ArduinoCI::CIConfig.default.from_example(cpp_lib_path)
        path         = config.allowable_unittest_files(@cpp_library.test_files).first
        compiler     = config.compilers_to_use.first
        result       = @cpp_library.build_for_test_with_configuration(path,
                                                                      [],
                                                                      compiler,
                                                                      config.gcc_config("uno"))
        expect(result).to be nil
      end
    end
  end

  context "with excludes" do

    context "cpp_files" do
      it "finds cpp files in directory" do
        @cpp_library = verified_install(backend, cpp_lib_path)
        @cpp_library.exclude_dirs = ["src/excludeThis"].map(&Pathname.method(:new))

        excludesomething_cpp_files = [
          Pathname.new("ExcludeSomething/src/exclude-something.cpp")
        ]
        relative_paths = @cpp_library.cpp_files.map { |f| f.relative_path_from(@base_dir) }
        expect(relative_paths).to match_array(excludesomething_cpp_files)
      end
    end

  end

end

RSpec.describe ArduinoCI::CppLibrary do
  next if skip_ruby_tests

  context "compiler flags" do
    config = ArduinoCI::CIConfig.new
    config.load_yaml(File.join(File.dirname(__FILE__), "yaml", "o1.yaml"))
    bogo_config = config.gcc_config("bogo")
    fld = FakeLibDir.new
    backend = fld.backend
    cpp_lib_path = sampleproj_path + "DoSomething"
    cpp_library = verified_install(backend, cpp_lib_path)

    # the keys are the methods of cpp_library to call
    # the results are what we expect to see based on the config we loaded
    methods_and_results = {
      feature_args: ["-fa", "-fb"],
      warning_args: ["-We", "-Wf"],
      define_args: ["-Dc", "-Dd"],
      flag_args: ["g", "h"]
    }

    methods_and_results.each do |m, expected|
      it "Creates #{m} from config" do
        expect(expected).to eq(cpp_library.send(m, bogo_config))
      end
    end

  end

  context "arduino-library-specification detection" do

    answers = {
      DoSomething: {
        one_five: false,
        library_properties: true,
        cpp_files: [Pathname.new("DoSomething") + "do-something.cpp"],
        cpp_files_libraries: [],
        header_dirs: [Pathname.new("DoSomething")],
        arduino_library_src_dirs: [],
        test_files: [
          "DoSomething/test/bad-errormessages.cpp",
          "DoSomething/test/bad-null.cpp",
          "DoSomething/test/good-assert.cpp",
          "DoSomething/test/good-library.cpp",
          "DoSomething/test/good-null.cpp",
        ].map { |f| Pathname.new(f) }
      },
      OnePointOhDummy: {
        one_five: false,
        library_properties: false,
        cpp_files: [
          "OnePointOhDummy/YesBase.cpp",
          "OnePointOhDummy/utility/YesUtil.cpp",
        ].map { |f| Pathname.new(f) },
        cpp_files_libraries: [],
        header_dirs: [
          "OnePointOhDummy",
          "OnePointOhDummy/utility"
        ].map { |f| Pathname.new(f) },
        arduino_library_src_dirs: [],
        test_files: [
          "OnePointOhDummy/test/null.cpp",
        ].map { |f| Pathname.new(f) }
      },
      OnePointFiveMalformed: {
        one_five: false,
        library_properties: false,
        cpp_files: [
          "OnePointFiveMalformed/YesBase.cpp",
          "OnePointFiveMalformed/utility/YesUtil.cpp",
        ].map { |f| Pathname.new(f) },
        cpp_files_libraries: [],
        header_dirs: [
          "OnePointFiveMalformed",
          "OnePointFiveMalformed/utility"
        ].map { |f| Pathname.new(f) },
        arduino_library_src_dirs: [],
        test_files: []
      },
      OnePointFiveDummy: {
        one_five: true,
        library_properties: true,
        cpp_files: [
          "OnePointFiveDummy/src/YesSrc.cpp",
          "OnePointFiveDummy/src/subdir/YesSubdir.cpp",
        ].map { |f| Pathname.new(f) },
        cpp_files_libraries: [],
        header_dirs: [
          "OnePointFiveDummy/src",
          "OnePointFiveDummy/src/subdir",
        ].map { |f| Pathname.new(f) },
        arduino_library_src_dirs: [],
        test_files: [
          "OnePointFiveDummy/test/null.cpp",
        ].map { |f| Pathname.new(f) }
      }
    }

    # easier to construct this one from the other test cases
    answers[:DependOnSomething] = {
      one_five: true,
      library_properties: true,
      cpp_files: ["DependOnSomething/src/YesDeps.cpp"].map { |f| Pathname.new(f) },
      cpp_files_libraries: answers[:OnePointOhDummy][:cpp_files] + answers[:OnePointFiveDummy][:cpp_files],
      header_dirs: ["DependOnSomething/src"].map { |f| Pathname.new(f) }, # this is not recursive!
      arduino_library_src_dirs: answers[:OnePointOhDummy][:header_dirs] + answers[:OnePointFiveDummy][:header_dirs],
      test_files: [
          "DependOnSomething/test/null.cpp",
        ].map { |f| Pathname.new(f) }
    }

    answers.freeze

    answers.each do |sampleproject, expected|

      # we will need to install some dummy libraries into a fake location, so do that on demand
      fld = FakeLibDir.new
      backend = fld.backend

      context "#{sampleproject}" do
        cpp_lib_path = sampleproj_path + sampleproject.to_s
        around(:example) { |example| fld.in_pristine_fake_libraries_dir(example) }
        before(:each) do
          @base_dir = fld.libraries_dir
          @cpp_library = verified_install(backend, cpp_lib_path)
        end

        it "is a sane test env" do
          expect(sampleproject.to_s).to eq(@cpp_library.name)
        end

        it "detects 1.5 format" do
          expect(@cpp_library.one_point_five?).to eq(expected[:one_five])
        end

        it "detects library.properties" do
          expect(@cpp_library.library_properties?).to eq(expected[:library_properties])
        end


        context "cpp_files" do
          it "finds cpp files in directory" do
            relative_paths = @cpp_library.cpp_files.map { |f| f.relative_path_from(@base_dir) }
            expect(relative_paths.map(&:to_s)).to match_array(expected[:cpp_files].map(&:to_s))
          end
        end

        context "cpp_files_libraries" do
          it "finds cpp files in directories of dependencies" do
            @cpp_library.all_arduino_library_dependencies!  # side effect: installs them
            dependencies = @cpp_library.arduino_library_dependencies.nil? ? [] : @cpp_library.arduino_library_dependencies
            dependencies.each { |d| verified_install(backend, sampleproj_path + d) }
            relative_paths = @cpp_library.cpp_files_libraries(dependencies).map { |f| f.relative_path_from(@base_dir) }
            expect(relative_paths.map(&:to_s)).to match_array(expected[:cpp_files_libraries].map(&:to_s))
          end
        end

        context "header_dirs" do
          it "finds directories containing h files" do
            relative_paths = @cpp_library.header_dirs.map { |f| f.relative_path_from(@base_dir) }
            expect(relative_paths.map(&:to_s)).to match_array(expected[:header_dirs].map(&:to_s))
          end
        end

        context "tests_dir" do
          it "locates the tests directory" do
            # since we don't know where the CI system will install this stuff,
            # we need to go looking for a relative path to the SampleProjects directory
            # just to get our "expected" value
            relative_path = @cpp_library.tests_dir.relative_path_from(@base_dir)
            expect(relative_path.to_s).to eq("#{sampleproject}/test")
          end
        end

        context "examples_dir" do
          it "locates the examples directory" do
            relative_path = @cpp_library.examples_dir.relative_path_from(@base_dir)
            expect(relative_path.to_s).to eq("#{sampleproject}/examples")
          end
        end

        context "test_files" do
          it "finds cpp files in directory" do
            relative_paths = @cpp_library.test_files.map { |f| f.relative_path_from(@base_dir) }
            expect(relative_paths.map(&:to_s)).to match_array(expected[:test_files].map(&:to_s))
          end
        end

        context "arduino_library_src_dirs" do
          it "finds src dirs from dependent libraries" do
            # we explicitly feed in the internal dependencies
            dependencies = @cpp_library.arduino_library_dependencies.nil? ? [] : @cpp_library.arduino_library_dependencies
            dependencies.each { |d| verified_install(backend, sampleproj_path + d) }
            relative_paths = @cpp_library.arduino_library_src_dirs(dependencies).map { |f| f.relative_path_from(@base_dir) }
            expect(relative_paths.map(&:to_s)).to match_array(expected[:arduino_library_src_dirs].map(&:to_s))
          end
        end
      end
    end
  end

  context "test" do

    # we will need to install some dummy libraries into a fake location, so do that on demand
    fld = FakeLibDir.new
    backend = fld.backend
    cpp_lib_path = sampleproj_path + "DoSomething"
    config = ArduinoCI::CIConfig.default

    around(:example) { |example| fld.in_pristine_fake_libraries_dir(example) }
    before(:each) { @cpp_library = verified_install(backend, cpp_lib_path) }

    after(:each) do |example|
      if example.exception
        puts "Last command: #{@cpp_library.last_cmd}"
        puts "========== Stdout:"
        puts @cpp_library.last_out
        puts "========== Stderr:"
        puts @cpp_library.last_err
      end
    end

    it "is going to test more than one library" do
      test_files = @cpp_library.test_files
      expect(test_files.empty?).to be false
    end

    test_files = Pathname.glob(Pathname.new(cpp_lib_path) + "test" + "*.cpp")
    test_files.each do |path|
      expected = path.basename.to_s.include?("good")
      config.compilers_to_use.each do |compiler|
        it "tests #{File.basename(path)} with #{compiler} expecting #{expected}" do
          exe = @cpp_library.build_for_test_with_configuration(path, [], compiler, config.gcc_config("uno"))
          expect(exe).not_to be nil
          expect(@cpp_library.run_test_file(Pathname.new(exe.path))).to eq(expected)
        end
      end
    end
  end

end
