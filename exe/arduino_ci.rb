#!/usr/bin/env ruby
require 'arduino_ci'
require 'set'
require 'pathname'
require 'optparse'

VAR_CUSTOM_INIT_SCRIPT = "CUSTOM_INIT_SCRIPT".freeze
VAR_USE_SUBDIR         = "USE_SUBDIR".freeze
VAR_EXPECT_EXAMPLES    = "EXPECT_EXAMPLES".freeze
VAR_EXPECT_UNITTESTS   = "EXPECT_UNITTESTS".freeze

CLI_SKIP_EXAMPLES_COMPILATION = "--skip-examples-compilation".freeze
CLI_SKIP_UNITTESTS            = "--skip-unittests".freeze

# script-level variables we'll use
@log         = nil
@backend     = nil
@cli_options = nil

# Use some basic parsing to allow command-line overrides of config
class Parser

  def self.show_help(opts)
    puts opts
    puts
    puts "Additionally, the following environment variables control the script:"
    puts " - #{VAR_CUSTOM_INIT_SCRIPT} - if set, this script will be run from the Arduino/libraries directory"
    puts "       prior to any automated library installation or testing (e.g. to install unofficial libraries)"
    puts " - #{VAR_USE_SUBDIR} - if set, the script will install the library from this subdirectory of the cwd"
    puts " - #{VAR_EXPECT_EXAMPLES} - if set, testing will fail if no example sketches are present"
    puts " - #{VAR_EXPECT_UNITTESTS} - if set, testing will fail if no unit tests are present"
  end

  def self.parse(options)
    unit_config = {}
    output_options = {
      skip_unittests: false,
      skip_compilation: false,
      ci_config: {
        "unittest" => unit_config
      },
      min_free_space: nil,
    }

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

      opts.on(CLI_SKIP_UNITTESTS, "Don't run unit tests") do |p|
        output_options[:skip_unittests] = p
      end

      opts.on(CLI_SKIP_EXAMPLES_COMPILATION, "Don't compile example sketches") do |p|
        output_options[:skip_compilation] = p
      end

      opts.on("--testfile-select=GLOB", "Unit test file (or glob) to select") do |p|
        unit_config["testfiles"] ||= {}
        unit_config["testfiles"]["select"] ||= []
        unit_config["testfiles"]["select"] << p
      end

      opts.on("--testfile-reject=GLOB", "Unit test file (or glob) to reject") do |p|
        unit_config["testfiles"] ||= {}
        unit_config["testfiles"]["reject"] ||= []
        unit_config["testfiles"]["reject"] << p
      end

      opts.on("--min-free-space=VALUE", "Minimum free SRAM memory for stack/heap, in bytes") do |p|
        output_options[:min_free_space] = p.to_i
      end

      opts.on("-h", "--help", "Prints this help") do
        show_help(opts)
        exit
      end
    end

    begin
      opt_parser.parse!(options)
    rescue OptionParser::InvalidOption => e
      puts e
      puts
      show_help(opt_parser)
      exit 1
    end
    output_options
  end
end

# print debugging information from the backend, to be used when things don't go as expected
def print_backend_logs
  @log.iputs "========== Last backend command (if relevant):"
  @log.iputs @backend.last_msg.to_s
  @log.iputs "========== Backend Stdout:"
  @log.iputs @backend.last_out
  @log.iputs "========== Backend Stderr:"
  @log.iputs @backend.last_err
end

# describe the last command, to help troubleshoot a failure
#
# @param cpp_library [CppLibrary]
def describe_last_command(cpp_library)
  @log.iputs "Last command: #{cpp_library.last_cmd}"
  @log.iputs cpp_library.last_out
  @log.iputs cpp_library.last_err
end

# terminate after printing any debug info.  TODO: capture debug info
def terminate(final = nil)
  puts "Failures: #{@log.failure_count}"
  print_backend_logs unless @log.failure_count.zero? || final || @backend.nil?
  retcode = @log.failure_count.zero? ? 0 : 1
  exit(retcode)
end

# Assure that a platform exists and return its definition
def assured_platform(purpose, name, config)
  platform_definition = config.platform_definition(name)
  @log.assure("Requested #{purpose} platform '#{name}' is defined in 'platforms' YML") { !platform_definition.nil? }
  platform_definition
end

# Perform a config override while explaining it to the user
def inform_override(from_where, &block)
  @log.inform("Using configuration override from #{from_where}") do
    file = block.call
    file.nil? ? "<none>" : file
  end
end

# Return true if the file (or one of the dirs containing it) is hidden
def file_is_hidden_somewhere?(path)
  # this is clunkly but pre-2.2-ish ruby doesn't return ascend as an enumerator
  path.ascend do |part|
    return true if part.basename.to_s.start_with? "."
  end
  false
end

# print out some files
def display_files(pathname)
  # `find` doesn't follow symlinks, so we should instead
  realpath = ArduinoCI::Host.symlink?(pathname) ? ArduinoCI::Host.readlink(pathname) : pathname

  # suppress directories and dotfile-based things
  all_files = realpath.find.select(&:file?)
  non_hidden = all_files.reject { |path| file_is_hidden_somewhere?(path) }

  # print files with an indent
  @log.iputs "Files (excluding hidden files): #{non_hidden.size}"
  @log.indent { non_hidden.each(&@log.method(:iputs)) }
end

# helper recursive function for library installation
#
# This recursively descends the dependency tree starting from an initial list,
# and either uses existing installations (based on directory naming only) or
# forcibly installs the dependency.  Each child dependency logs which parent requested it
#
# @param library_names [Array<String>] the list of libraries to install
# @param on_behalf_of [String] the requestor of a given dependency
# @param already_installed [Array<String>] the set of dependencies installed by previous steps
# @return [Array<String>] The list of installed libraries
def install_arduino_library_dependencies_h(library_names, on_behalf_of, already_installed)
  installed = already_installed.clone
  (library_names.map { |n| @backend.library_of_name(n) } - installed).each do |l|
    if l.installed?
      @log.inform("Using pre-existing dependency of #{on_behalf_of}") { l.name }
    else
      @log.assure("Installing dependency of #{on_behalf_of}: '#{l.name}'") do
        next nil unless l.install

        l.name
      end
    end
    installed << l.name
    installed += install_arduino_library_dependencies_h(l.arduino_library_dependencies, l.name, installed)
  end
  installed
end

# @return [Array<String>] The list of installed libraries
def install_arduino_library_dependencies(library_names, on_behalf_of)
  if library_names.empty?
    @log.inform("Arduino library dependencies (configured in #{on_behalf_of}) to resolve") { library_names.length }
    return []
  end

  @log.inform_multiline("Resolving #{library_names.length} Arduino library dependencies configured in #{on_behalf_of})") do
    install_arduino_library_dependencies_h(library_names, on_behalf_of, [])
  end
end

# @param platforms [Array<String>] list of platforms to consider
# @param specific_config [CIConfig] configuration to use
def install_all_packages(platforms, specific_config)

  # get packages from platforms
  all_packages = specific_config.platform_info.select { |p, _| platforms.include?(p) }.values.map { |v| v[:package] }.compact.uniq

  all_packages.each do |pkg|
    next if @backend.boards_installed?(pkg)

    url = @log.assure("Board package #{pkg} has a defined URL") { specific_config.package_url(pkg) }
    @backend.board_manager_urls = [url]
    @log.assure("Installing board package #{pkg}") { @backend.install_boards(pkg) }
  end
end

# @param expectation_envvar [String] the name of the env var to check
# @param operation [String] a description of what operation we might be skipping
# @param howto_skip [String] a description of how the runner can skip this
# @param filegroup_name [String] a description of the set of files without which we effectively skip the operation
# @param dir_description [String] a description of the directory where we looked for the files
# @param dir [Pathname] the directory where we looked for the files
def handle_expectation_of_files(expectation_envvar, operation, howto_skip, filegroup_name, dir_description, dir_path)
  # alert future me about running the script from the wrong directory, instead of doing the huge file dump
  # otherwise, assume that the user might be running the script on a library with no actual unit tests
  if Pathname.new(__dir__).parent == Pathname.new(Dir.pwd)
    @log.inform_multiline("arduino_ci seems to be trying to test itself") do
      [
        "arduino_ci (the ruby gem) isn't an arduino project itself, so running the CI test script against",
        "the core library isn't really a valid thing to do... but it's easy for a developer (including the",
        "owner) to mistakenly do just that.  Hello future me, you probably meant to run this against one of",
        "the sample projects in SampleProjects/ ... if not, please submit a bug report; what a wild case!"
      ].each(&@log.method(:iputs))
      false
    end
    exit(1)
  end

  # either the directory is empty, or it doesn't exist at all. message accordingly.
  (problem, dir_desc, dir) = if dir_path.exist?
    ["No #{filegroup_name} were found in", dir_description, dir_path]
  else
    ["No #{dir_description} at", "base directory", dir_path.parent]
  end

  @log.inform(problem) { dir_path }
  explain_and_exercise_envvar(expectation_envvar, operation, howto_skip, "contents of #{dir_desc}") { display_files(dir) }
end

# @param expectation_envvar [String] the name of the env var to check
# @param operation [String] a description of what operation we might be skipping
# @param howto_skip [String] a description of how the runner can skip this
# @param block_desc [String] a description of what information will be dumped to assist the user
# @param block [Proc] a function that dumps information
def explain_and_exercise_envvar(expectation_envvar, operation, howto_skip, block_desc, &block)
  @log.inform("Environment variable #{expectation_envvar} is") { "(#{ENV[expectation_envvar].class}) #{ENV[expectation_envvar]}" }
  if ENV[expectation_envvar].nil?
    @log.inform_multiline("Skipping #{operation}") do
      @log.iputs "In case that's an error, displaying #{block_desc}:"
      block.call
      @log.iputs "To force an error in this case, set the environment variable #{expectation_envvar}"
      @log.iputs "To explicitly skip this check, use #{howto_skip}"
      true
    end
  else
    @log.assure_multiline("Displaying #{block_desc} before exit") do
      block.call
      false
    end
  end
end

# report and return the set of compilers
def get_annotated_compilers(config, cpp_library)
  # check GCC
  compilers = config.compilers_to_use
  @log.assure("The set of compilers (#{compilers.length}) isn't empty") { !compilers.empty? }
  compilers.each do |gcc_binary|
    @log.attempt_multiline("Checking #{gcc_binary} version") do
      version = cpp_library.gcc_version(gcc_binary)
      next nil unless version

      @log.iputs(version)
      version
    end
    @log.inform("libasan availability for #{gcc_binary}") { cpp_library.libasan?(gcc_binary) }
  end
  compilers
end

# Handle existence or nonexistence of custom initialization script -- run it if you have it
#
# This feature is to drive GitHub actions / docker image installation where the container is
# in a clean-slate state but needs some way to have custom library versions injected into it.
# In this case, the user provided script would fetch a git repo or some other method
def perform_custom_initialization(_config)
  script_path = ENV[VAR_CUSTOM_INIT_SCRIPT]
  @log.inform("Environment variable #{VAR_CUSTOM_INIT_SCRIPT}") { "'#{script_path}'" }
  return if script_path.nil?
  return if script_path.empty?

  script_pathname = Pathname.getwd + script_path
  @log.assure("Script at #{VAR_CUSTOM_INIT_SCRIPT} exists") { script_pathname.exist? }

  @log.assure_multiline("Running #{script_pathname} with sh in libraries working dir") do
    Dir.chdir(@backend.lib_dir) do
      IO.popen(["/bin/sh", script_pathname.to_s], err: [:child, :out]) do |io|
        @log.indent { io.each_line(&@log.method(:iputs)) }
      end
    end
  end
end

# Kick off the arduino_ci test process by explaining and adjusting the environment
#
# @return Hash of things needed for later steps
def perform_bootstrap
  @log.inform("Host OS") { ArduinoCI::Host.os }
  @log.inform("Working directory") { Dir.pwd }

  # initialize command and config
  default_config = ArduinoCI::CIConfig.default
  inform_override("project") { default_config.override_file_from_project_library }
  config = default_config.from_project_library

  backend = ArduinoCI::ArduinoInstallation.autolocate!
  @log.inform("Located arduino-cli binary") { backend.binary_path.to_s }
  @log.inform("Using arduino-cli version") { backend.version.to_s }
  if backend.lib_dir.exist?
    @log.inform("Found libraries directory") { backend.lib_dir }
  else
    @log.assure("Creating libraries directory") { backend.lib_dir.mkpath || true }
  end

  # run any library init scripts from the library itself.
  perform_custom_initialization(config)

  # initialize library under test
  @log.inform("Environment variable #{VAR_USE_SUBDIR}") { "'#{ENV[VAR_USE_SUBDIR]}'" }
  cpp_library_path = Pathname.new(ENV[VAR_USE_SUBDIR].nil? ? "." : ENV[VAR_USE_SUBDIR])
  cpp_library = @log.assure("Installing library under test") do
    backend.install_local_library(cpp_library_path)
  end

  # Warn if the library name isn't obvious
  assumed_name = backend.name_of_library(cpp_library_path)
  ondisk_name = cpp_library_path.realpath.basename.to_s
  @log.warn("Installed library named '#{assumed_name}' has directory name '#{ondisk_name}'") if assumed_name != ondisk_name

  if !cpp_library.nil?
    @log.inform("Library installed at") { cpp_library.path.to_s }
  else
    # this is a longwinded way of failing, we aren't really "assuring" anything at this point
    @log.assure_multiline("Library installed successfully") do
      @log.iputs backend.last_msg
      false
    end
  end

  # return all objects needed by other steps
  {
    backend: backend,
    cpp_library: cpp_library,
    config: config,
  }
end

# Auto-select some platforms to test based on the information available
#
# Top choice is always library.properties -- otherwise use the default.
# But filter that through any non-default config
#
# @param config [CIConfig] the overridden config object
# @param reason [String] description of why we might use this platform (i.e. unittest or compilation)
# @param desired_platforms [Array<String>] the platform names specified
# @param library_properties [Hash] the library properties defined by the library
# @return [Array<String>] platforms to use
def choose_platform_set(config, reason, desired_platforms, library_properties)

  # if there are no properties or no architectures, defer entirely to desired platforms
  if library_properties.nil? || library_properties.architectures.nil? || library_properties.architectures.empty?
    # verify that all platforms exist
    desired_platforms.each { |p| assured_platform(reason, p, config) }
    return @log.inform_multiline("No architectures listed in library.properties, using configured platforms") do
      desired_platforms.each(&@log.method(:iputs)) # this returns desired_platforms
    end
  end

  if library_properties.architectures.include?("*")
    return @log.inform_multiline("Wildcard architecture in library.properties, using configured platforms") do
      desired_platforms.each(&@log.method(:iputs)) # this returns desired_platforms
    end
  end

  platform_architecture = config.platform_info.transform_values { |v| v[:board].split(":")[1] }
  supported_platforms = platform_architecture.select { |_, a| library_properties.architectures.include?(a) }

  if config.is_default
    # completely ignore default config, opting for brute-force library matches
    # OTOH, we don't need to assure platforms because we defined them
    return @log.inform_multiline("Default config, platforms matching architectures in library.properties") do
      supported_platforms.keys.each do |p|  # rubocop:disable Style/HashEachMethods
        @log.iputs(p)
      end # this returns supported_platforms
    end
  end

  desired_supported_platforms = supported_platforms.select { |p, _| desired_platforms.include?(p) }.keys
  desired_supported_platforms.each { |p| assured_platform(reason, p, config) }
  @log.inform_multiline("Configured platforms that match architectures in library.properties") do
    desired_supported_platforms.each do |p|
      @log.iputs(p)
    end # this returns supported_platforms
  end
end

# Unit test procedure
def perform_unit_tests(cpp_library, file_config)
  @log.phase("Unit testing")
  if @cli_options[:skip_unittests]
    @log.inform("Skipping unit tests") { "as requested via command line" }
    return
  end

  config = file_config.with_override_config(@cli_options[:ci_config])
  compilers = get_annotated_compilers(config, cpp_library)

  @log.inform("Library conforms to Arduino library specification") { cpp_library.one_point_five? ? "1.5" : "1.0" }

  # Handle lack of test files
  if cpp_library.test_files.empty?
    handle_expectation_of_files(
      VAR_EXPECT_UNITTESTS,
      "unit tests",
      CLI_SKIP_UNITTESTS,
      "test files",
      "tests directory",
      cpp_library.tests_dir
    )
    return
  end

  # Get platforms, handle lack of them
  platforms = choose_platform_set(config, "unittest", config.platforms_to_unittest, cpp_library.library_properties)
  if platforms.empty?
    explain_and_exercise_envvar(VAR_EXPECT_UNITTESTS, "unit tests", CLI_SKIP_UNITTESTS, "platforms and architectures") do
      @log.iputs "Configured platforms: #{config.platforms_to_unittest}"
      @log.iputs "Configuration is default: #{config.is_default}"
      arches = cpp_library.library_properties.nil? ? nil : cpp_library.library_properties.architectures
      @log.iputs "Architectures in library.properties: #{arches}"
    end
  end

  # having undefined platforms is a config error
  platforms.select { |p| config.platform_info[p].nil? }.each do |p|
    @log.assure("Platform '#{p}' is defined in configuration files") { false }
  end

  install_arduino_library_dependencies(config.aux_libraries_for_unittest, "<unittest/libraries>")

  platforms.each do |p|
    @log.iputs
    compilers.each do |gcc_binary|
      # before compiling the tests, build a shared library of everything except the test code
      next @log.failure_count += 1 unless build_shared_library(gcc_binary, p, config, cpp_library)

      # now build and run each test using the shared library build above
      config.allowable_unittest_files(cpp_library.test_files).each do |unittest_path|
        unittest_name = unittest_path.basename.to_s
        @log.rule "-"
        @log.attempt_multiline("Unit testing #{unittest_name} with #{gcc_binary} for #{p}") do
          exe = cpp_library.build_for_test(unittest_path, gcc_binary)
          @log.iputs
          unless exe
            describe_last_command(cpp_library)
            next false
          end
          cpp_library.run_test_file(exe)
        end
      end
    end
  end
end

def build_shared_library(gcc_binary, platform, config, cpp_library)
  @log.attempt_multiline("Build shared library with #{gcc_binary} for #{platform}") do
    exe = cpp_library.build_shared_library(
      config.aux_libraries_for_unittest,
      gcc_binary,
      config.gcc_config(platform)
    )
    @log.iputs
    describe_last_command(cpp_library) unless exe
    exe
  end
end

def perform_example_compilation_tests(cpp_library, config)
  @log.phase("Compilation of example sketches")
  if @cli_options[:skip_compilation]
    @log.inform("Skipping compilation of examples") { "as requested via command line" }
    return
  end

  library_examples = cpp_library.example_sketches

  if library_examples.empty?
    handle_expectation_of_files(
      VAR_EXPECT_EXAMPLES,
      "builds",
      CLI_SKIP_EXAMPLES_COMPILATION,
      "examples",
      "the examples directory",
      cpp_library.examples_dir
    )
    return
  end

  inform_override("examples") { config.override_file_from_example(cpp_library.examples_dir) }
  ex_config = config.from_example(cpp_library.examples_dir)

  library_examples.each do |example_path|
    example_name = File.basename(example_path)
    @log.iputs
    @log.inform("Discovered example sketch") { example_name }

    inform_override("example") { ex_config.override_file_from_example(example_path) }
    ovr_config = ex_config.from_example(example_path)

    platforms = choose_platform_set(ovr_config, "library example", ovr_config.platforms_to_build, cpp_library.library_properties)

    # having no platforms defined is probably an error
    if platforms.empty?
      explain_and_exercise_envvar(
        VAR_EXPECT_EXAMPLES,
        "examples compilation",
        CLI_SKIP_EXAMPLES_COMPILATION,
        "platforms and architectures"
      ) do
        @log.iputs "Configured platforms: #{ovr_config.platforms_to_build}"
        @log.iputs "Configuration is default: #{ovr_config.is_default}"
        arches = cpp_library.library_properties.nil? ? nil : cpp_library.library_properties.architectures
        @log.iputs "Architectures in library.properties: #{arches}"
      end
    end

    # having undefined platforms is a config error
    platforms.select { |p| ovr_config.platform_info[p].nil? }.each do |p|
      @log.assure("Platform '#{p}' is defined in configuration files") { false }
    end

    install_all_packages(platforms, ovr_config)
    install_arduino_library_dependencies(ovr_config.aux_libraries_for_build, "<compile/libraries>")

    platforms.each do |p|
      board = ovr_config.platform_info[p][:board] # assured to exist, above
      compiled_ok = @log.attempt("Compiling #{example_name} for #{board}") do
        @backend.compile_sketch(example_path, board)
      end

      # decode the JSON output of the compiler a little bit
      unless compiled_ok
        @log.inform_multiline("Compilation failure details") do
          begin
            # parse the JSON, and print out only the nonempty keys. indent them with 4 spaces in their own labelled sections
            msg_json = JSON.parse(@backend.last_msg)
            msg_json.each do |k, v|
              val = if v.is_a?(Hash) || v.is_a?(Array)
                JSON.pretty_generate(v)
              else
                v.to_s
              end
              @log.inform_multiline(k) { @log.iputs(val) } unless val.strip.empty?
            end
          rescue JSON::ParserError
            # worst case: dump it
            @log.iputs "Last command: #{@backend.last_msg}"
          end
          @log.iputs @backend.last_err
        end
      end

      # reporting or enforcing of free space
      usage = @backend.last_bytes_usage
      @log.inform("Free space (bytes) after compilation") { usage[:free] }
      next if @cli_options[:min_free_space].nil?

      min_free_space = @cli_options[:min_free_space]
      @log.attempt("Free space exceeds desired minimum #{min_free_space}") do
        min_free_space <= usage[:free]
      end
    end
  end
end

###############################################################
# script execution
#

# Read in command line options and make them read-only
@cli_options = Parser.parse(ARGV).freeze

@log = ArduinoCI::Logger.auto_width
@log.banner

strap = perform_bootstrap
@backend = strap[:backend]

install_arduino_library_dependencies(
  strap[:cpp_library].arduino_library_dependencies,
  "<#{ArduinoCI::CppLibrary::LIBRARY_PROPERTIES_FILE}>"
)

perform_unit_tests(strap[:cpp_library], strap[:config])
perform_example_compilation_tests(strap[:cpp_library], strap[:config])

terminate(true)
