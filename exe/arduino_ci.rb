#!/usr/bin/env ruby
require 'arduino_ci'
require 'set'
require 'pathname'
require 'optparse'

WIDTH = 80
VAR_CUSTOM_INIT_SCRIPT = "CUSTOM_INIT_SCRIPT".freeze
VAR_USE_SUBDIR         = "USE_SUBDIR".freeze
VAR_EXPECT_EXAMPLES    = "EXPECT_EXAMPLES".freeze
VAR_EXPECT_UNITTESTS   = "EXPECT_UNITTESTS".freeze

@failure_count = 0
@passfail = proc { |result| result ? "✓" : "✗" }
@backend = nil

# Use some basic parsing to allow command-line overrides of config
class Parser
  def self.parse(options)
    unit_config = {}
    output_options = {
      skip_unittests: false,
      skip_compilation: false,
      ci_config: {
        "unittest" => unit_config
      },
    }

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

      opts.on("--skip-unittests", "Don't run unit tests") do |p|
        output_options[:skip_unittests] = p
      end

      opts.on("--skip-examples-compilation", "Don't compile example sketches") do |p|
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

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        puts
        puts "Additionally, the following environment variables control the script:"
        puts " - #{VAR_CUSTOM_INIT_SCRIPT} - if set, this script will be run from the Arduino/libraries directory"
        puts "       prior to any automated library installation or testing (e.g. to install unoffical libraries)"
        puts " - #{VAR_USE_SUBDIR} - if set, the script will install the library from this subdirectory of the cwd"
        puts " - #{VAR_EXPECT_EXAMPLES} - if set, testing will fail if no example sketches are present"
        puts " - #{VAR_EXPECT_UNITTESTS} - if set, testing will fail if no unit tests are present"
        puts " - #{VAR_SKIP_LIBPROPS} - if set, testing will skip [experimental] library.properties validation"
        exit
      end
    end

    opt_parser.parse!(options)
    output_options
  end
end

# Read in command line options and make them read-only
@cli_options = (Parser.parse ARGV).freeze

# terminate after printing any debug info.  TODO: capture debug info
def terminate(final = nil)
  puts "Failures: #{@failure_count}"
  unless @failure_count.zero? || final || @backend.nil?
    puts "========== Last backend command (if relevant):"
    puts @backend.last_msg.to_s
    puts "========== Backend Stdout:"
    puts @backend.last_out
    puts "========== Backend Stderr:"
    puts @backend.last_err
  end
  retcode = @failure_count.zero? ? 0 : 1
  exit(retcode)
end

# make a nice status line for an action and react to the action
# TODO / note to self: inform_multline is tougher to write
#   without altering the signature because it only leaves space
#   for the checkmark _after_ the multiline, it doesn't know how
#   to make that conditionally the body
# @param message String the text of the progress indicator
# @param multiline boolean whether multiline output is expected
# @param mark_fn block (string) -> string that says how to describe the result
# @param on_fail_msg String custom message for failure
# @param tally_on_fail boolean whether to increment @failure_count
# @param abort_on_fail boolean whether to abort immediately on failure (i.e. if this is a fatal error)
def perform_action(message, multiline, mark_fn, on_fail_msg, tally_on_fail, abort_on_fail)
  line = "#{message}... "
  endline = "...#{message} "
  if multiline
    puts line
  else
    print line
  end
  $stdout.flush
  result = yield
  mark = mark_fn.nil? ? "" : mark_fn.call(result)
  # if multline, put checkmark at full width
  print endline if multiline
  puts mark.to_s.rjust(WIDTH - line.length, " ")
  unless result
    puts on_fail_msg unless on_fail_msg.nil?
    @failure_count += 1 if tally_on_fail
    # print out error messaging here if we've captured it
    terminate if abort_on_fail
  end
  result
end

# Make a nice status for something that defers any failure code until script exit
def attempt(message, &block)
  perform_action(message, false, @passfail, nil, true, false, &block)
end

# Make a nice status for something that defers any failure code until script exit
def attempt_multiline(message, &block)
  perform_action(message, true, @passfail, nil, true, false, &block)
end

# Make a nice status for something that kills the script immediately on failure
FAILED_ASSURANCE_MESSAGE = "This may indicate a problem with your configuration; halting here".freeze
def assure(message, &block)
  perform_action(message, false, @passfail, FAILED_ASSURANCE_MESSAGE, true, true, &block)
end

def assure_multiline(message, &block)
  perform_action(message, true, @passfail, FAILED_ASSURANCE_MESSAGE, true, true, &block)
end

def inform(message, &block)
  perform_action(message, false, proc { |x| x }, nil, false, false, &block)
end

def inform_multiline(message, &block)
  perform_action(message, true, nil, nil, false, false, &block)
end

def rule(char)
  puts char[0] * WIDTH
end

def warn(message)
  inform("WARNING") { message }
end

def phase(name)
  puts
  rule("=")
  inform("Beginning the next phase of testing") { name }
end

def banner
  art = [
    "         .                  __  ___",
    " _, ,_  _| , . * ._   _    /  `  | ",
    "(_| [ `(_] (_| | [ ) (_)   \\__. _|_   v#{ArduinoCI::VERSION}",
  ]

  pad = " " * ((WIDTH - art[2].length) / 2)
  art.each { |l| puts "#{pad}#{l}" }
  puts
end

# Assure that a platform exists and return its definition
def assured_platform(purpose, name, config)
  platform_definition = config.platform_definition(name)
  assure("Requested #{purpose} platform '#{name}' is defined in 'platforms' YML") { !platform_definition.nil? }
  platform_definition
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
  puts "  Files (excluding hidden files): #{non_hidden.size}"
  non_hidden.each { |p| puts "    #{p}" }
end

# @return [Array<String>] The list of installed libraries
def install_arduino_library_dependencies(library_names, on_behalf_of, already_installed = [])
  installed = already_installed.clone
  (library_names.map { |n| @backend.library_of_name(n) } - installed).each do |l|
    if l.installed?
      inform("Using pre-existing dependency of #{on_behalf_of}") { l.name }
    else
      assure("Installing dependency of #{on_behalf_of}: '#{l.name}'") do
        next nil unless l.install

        l.name
      end
    end
    installed << l.name
    installed += install_arduino_library_dependencies(l.arduino_library_dependencies, l.name, installed)
  end
  installed
end

# @param platforms [Array<String>] list of platforms to consider
# @param specific_config [CIConfig] configuration to use
def install_all_packages(platforms, specific_config)

  # get packages from platforms
  all_packages = specific_config.platform_info.select { |p, _| platforms.include?(p) }.values.map { |v| v[:package] }.compact.uniq

  all_packages.each do |pkg|
    next if @backend.boards_installed?(pkg)

    url = assure("Board package #{pkg} has a defined URL") { specific_config.package_url(pkg) }
    @backend.board_manager_urls = [url]
    assure("Installing board package #{pkg}") { @backend.install_boards(pkg) }
  end
end

# @param expectation_envvar [String] the name of the env var to check
# @param operation [String] a description of what operation we might be skipping
# @param filegroup_name [String] a description of the set of files without which we effectively skip the operation
# @param dir_description [String] a description of the directory where we looked for the files
# @param dir [Pathname] the directory where we looked for the files
def handle_expectation_of_files(expectation_envvar, operation, filegroup_name, dir_description, dir_path)
  # alert future me about running the script from the wrong directory, instead of doing the huge file dump
  # otherwise, assume that the user might be running the script on a library with no actual unit tests
  if Pathname.new(__dir__).parent == Pathname.new(Dir.pwd)
    inform_multiline("arduino_ci seems to be trying to test itself") do
      [
        "arduino_ci (the ruby gem) isn't an arduino project itself, so running the CI test script against",
        "the core library isn't really a valid thing to do... but it's easy for a developer (including the",
        "owner) to mistakenly do just that.  Hello future me, you probably meant to run this against one of",
        "the sample projects in SampleProjects/ ... if not, please submit a bug report; what a wild case!"
      ].each { |l| puts "  #{l}" }
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

  inform(problem) { dir_path }
  explain_and_exercise_envvar(expectation_envvar, operation, "contents of #{dir_desc}") { display_files(dir) }
end

# @param expectation_envvar [String] the name of the env var to check
# @param operation [String] a description of what operation we might be skipping
# @param block_desc [String] a description of what information will be dumped to assist the user
# @param block [Proc] a function that dumps information
def explain_and_exercise_envvar(expectation_envvar, operation, block_desc, &block)
  inform("Environment variable #{expectation_envvar} is") { "(#{ENV[expectation_envvar].class}) #{ENV[expectation_envvar]}" }
  if ENV[expectation_envvar].nil?
    inform_multiline("Skipping #{operation}") do
      puts "  In case that's an error, displaying #{block_desc}:"
      block.call
      puts "  To force an error in this case, set the environment variable #{expectation_envvar}"
      true
    end
  else
    assure_multiline("Displaying #{block_desc} before exit") do
      block.call
      false
    end
  end
end

# report and return the set of compilers
def get_annotated_compilers(config, cpp_library)
  # check GCC
  compilers = config.compilers_to_use
  assure("The set of compilers (#{compilers.length}) isn't empty") { !compilers.empty? }
  compilers.each do |gcc_binary|
    attempt_multiline("Checking #{gcc_binary} version") do
      version = cpp_library.gcc_version(gcc_binary)
      next nil unless version

      puts version.split("\n").map { |l| "    #{l}" }.join("\n")
      version
    end
    inform("libasan availability for #{gcc_binary}") { cpp_library.libasan?(gcc_binary) }
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
  inform("Environment variable #{VAR_CUSTOM_INIT_SCRIPT}") { "'#{script_path}'" }
  return if script_path.nil?
  return if script_path.empty?

  script_pathname = Pathname.getwd + script_path
  assure("Script at #{VAR_CUSTOM_INIT_SCRIPT} exists") { script_pathname.exist? }

  assure_multiline("Running #{script_pathname} with sh in libraries working dir") do
    Dir.chdir(@backend.lib_dir) do
      IO.popen(["/bin/sh", script_pathname.to_s], err: [:child, :out]) do |io|
        io.each_line { |line| puts "    #{line}" }
      end
    end
  end
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
    return inform_multiline("No architectures listed in library.properties, using configured platforms") do
      desired_platforms.each { |p| puts "    #{p}" } # this returns desired_platforms
    end
  end

  if library_properties.architectures.include?("*")
    return inform_multiline("Wildcard architecture in library.properties, using configured platforms") do
      desired_platforms.each { |p| puts "    #{p}" } # this returns desired_platforms
    end
  end

  platform_architecture = config.platform_info.transform_values { |v| v[:board].split(":")[1] }
  supported_platforms = platform_architecture.select { |_, a| library_properties.architectures.include?(a) }

  if config.is_default
    # completely ignore default config, opting for brute-force library matches
    # OTOH, we don't need to assure platforms because we defined them
    return inform_multiline("Default config, platforms matching architectures in library.properties") do
      supported_platforms.keys.each do |p|  # rubocop:disable Style/HashEachMethods
        puts "    #{p}"
      end # this returns supported_platforms
    end
  end

  desired_supported_platforms = supported_platforms.select { |p, _| desired_platforms.include?(p) }.keys
  desired_supported_platforms.each { |p| assured_platform(reason, p, config) }
  inform_multiline("Configured platforms that match architectures in library.properties") do
    desired_supported_platforms.each do |p|
      puts "    #{p}"
    end # this returns supported_platforms
  end
end

# Unit test procedure
def perform_unit_tests(cpp_library, file_config)
  phase("Unit testing")
  if @cli_options[:skip_unittests]
    inform("Skipping unit tests") { "as requested via command line" }
    return
  end

  config = file_config.with_override_config(@cli_options[:ci_config])
  compilers = get_annotated_compilers(config, cpp_library)

  inform("Library conforms to Arduino library specification") { cpp_library.one_point_five? ? "1.5" : "1.0" }

  # Handle lack of test files
  if cpp_library.test_files.empty?
    handle_expectation_of_files(VAR_EXPECT_UNITTESTS, "unit tests", "test files", "tests directory", cpp_library.tests_dir)
    return
  end

  # Get platforms, handle lack of them
  platforms = choose_platform_set(config, "unittest", config.platforms_to_unittest, cpp_library.library_properties)
  if platforms.empty?
    explain_and_exercise_envvar(VAR_EXPECT_UNITTESTS, "unit tests", "platforms and architectures") do
      puts "    Configured platforms: #{config.platforms_to_unittest}"
      puts "    Configuration is default: #{config.is_default}"
      arches = cpp_library.library_properties.nil? ? nil : cpp_library.library_properties.architectures
      puts "    Architectures in library.properties: #{arches}"
    end
  end

  install_arduino_library_dependencies(config.aux_libraries_for_unittest, "<unittest/libraries>")

  platforms.each do |p|
    puts
    compilers.each do |gcc_binary|
      # before compiling the tests, build a shared library of everything except the test code
      attempt_multiline("Build shared library with #{gcc_binary} for #{p}") do
        exe = cpp_library.build_for_test_with_configuration(
          nil, # nil is a flag that we are building the shared library with everything else
          config.aux_libraries_for_unittest,
          gcc_binary,
          config.gcc_config(p)
        )
        puts
        unless exe
          puts "Last command: #{cpp_library.last_cmd}"
          puts cpp_library.last_out
          puts cpp_library.last_err
          next false
        end
        true
      end
      # now build and run each test using the shared library build above
      config.allowable_unittest_files(cpp_library.test_files).each do |unittest_path|
        unittest_name = unittest_path.basename.to_s
        attempt_multiline("Unit testing #{unittest_name} with #{gcc_binary} for #{p}") do
          exe = cpp_library.build_for_test_with_configuration(
            unittest_path,
            config.aux_libraries_for_unittest,
            gcc_binary,
            config.gcc_config(p)
          )
          puts
          unless exe
            puts "Last command: #{cpp_library.last_cmd}"
            puts cpp_library.last_out
            puts cpp_library.last_err
            next false
          end
          cpp_library.run_test_file(exe)
        end
      end
    end
  end
end

def perform_example_compilation_tests(cpp_library, config)
  phase("Compilation of example sketches")
  if @cli_options[:skip_compilation]
    inform("Skipping compilation of examples") { "as requested via command line" }
    return
  end

  library_examples = cpp_library.example_sketches

  if library_examples.empty?
    handle_expectation_of_files(VAR_EXPECT_EXAMPLES, "builds", "examples", "the examples directory", cpp_library.examples_dir)
    return
  end

  library_examples.each do |example_path|
    example_name = File.basename(example_path)
    puts
    inform("Discovered example sketch") { example_name }

    ovr_config = config.from_example(example_path)
    platforms = choose_platform_set(ovr_config, "library example", ovr_config.platforms_to_build, cpp_library.library_properties)

    if platforms.empty?
      explain_and_exercise_envvar(VAR_EXPECT_EXAMPLES, "examples compilation", "platforms and architectures") do
        puts "    Configured platforms: #{ovr_config.platforms_to_build}"
        puts "    Configuration is default: #{ovr_config.is_default}"
        arches = cpp_library.library_properties.nil? ? nil : cpp_library.library_properties.architectures
        puts "    Architectures in library.properties: #{arches}"
      end
    end

    install_all_packages(platforms, ovr_config)
    install_arduino_library_dependencies(ovr_config.aux_libraries_for_build, "<compile/libraries>")

    platforms.each do |p|
      board = ovr_config.platform_info[p][:board]
      attempt("Compiling #{example_name} for #{board}") do
        ret = @backend.compile_sketch(example_path, board)
        unless ret
          puts
          puts "Last command: #{@backend.last_msg}"
          puts @backend.last_err
        end
        ret
      end
    end
  end
end

banner
inform("Host OS") { ArduinoCI::Host.os }

# initialize command and config
config = ArduinoCI::CIConfig.default.from_project_library
@backend = ArduinoCI::ArduinoInstallation.autolocate!
inform("Located arduino-cli binary") { @backend.binary_path.to_s }
if @backend.lib_dir.exist?
  inform("Found libraries directory") { @backend.lib_dir }
else
  assure("Creating libraries directory") { @backend.lib_dir.mkpath || true }
end

# run any library init scripts from the library itself.
perform_custom_initialization(config)

# initialize library under test
inform("Environment variable #{VAR_USE_SUBDIR}") { "'#{ENV[VAR_USE_SUBDIR]}'" }
cpp_library_path = Pathname.new(ENV[VAR_USE_SUBDIR].nil? ? "." : ENV[VAR_USE_SUBDIR])
cpp_library = assure("Installing library under test") do
  @backend.install_local_library(cpp_library_path)
end

# Warn if the library name isn't obvious
assumed_name = @backend.name_of_library(cpp_library_path)
ondisk_name = cpp_library_path.realpath.basename.to_s
warn("Installed library named '#{assumed_name}' has directory name '#{ondisk_name}'") if assumed_name != ondisk_name

if !cpp_library.nil?
  inform("Library installed at") { cpp_library.path.to_s }
else
  # this is a longwinded way of failing, we aren't really "assuring" anything at this point
  assure_multiline("Library installed successfully") do
    puts @backend.last_msg
    false
  end
end

install_arduino_library_dependencies(
  cpp_library.arduino_library_dependencies,
  "<#{ArduinoCI::CppLibrary::LIBRARY_PROPERTIES_FILE}>"
)

perform_unit_tests(cpp_library, config)
perform_example_compilation_tests(cpp_library, config)

terminate(true)
