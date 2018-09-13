#!/usr/bin/env ruby
require 'arduino_ci'
require 'set'
require 'pathname'

WIDTH = 80

@failure_count = 0
@passfail = proc { |result| result ? "✓" : "✗" }

# terminate after printing any debug info.  TODO: capture debug info
def terminate(final = nil)
  puts "Failures: #{@failure_count}"
  unless @failure_count.zero? || final
    puts "Last message: #{@arduino_cmd.last_msg}"
    puts "========== Stdout:"
    puts @arduino_cmd.last_out
    puts "========== Stderr:"
    puts @arduino_cmd.last_err
  end
  retcode = @failure_count.zero? ? 0 : 1
  exit(retcode)
end

# make a nice status line for an action and react to the action
def perform_action(message, multiline, mark_fn, on_fail_msg, abort_on_fail)
  line = "#{message}... "
  endline = "...#{message} "
  if multiline
    puts line
  else
    print line
  end
  STDOUT.flush
  result = yield
  mark = mark_fn.nil? ? "" : mark_fn.call(result)
  # if multline, put checkmark at full width
  print endline if multiline
  puts mark.rjust(WIDTH - line.length, " ")
  unless result
    puts on_fail_msg unless on_fail_msg.nil?
    @failure_count += 1
    # print out error messaging here if we've captured it
    terminate if abort_on_fail
  end
  result
end

# Make a nice status for something that defers any failure code until script exit
def attempt(message, &block)
  perform_action(message, false, @passfail, nil, false, &block)
end

# Make a nice status for something that defers any failure code until script exit
def attempt_multiline(message, &block)
  perform_action(message, true, @passfail, nil, false, &block)
end

# Make a nice status for something that kills the script immediately on failure
def assure(message, &block)
  perform_action(message, false, @passfail, "This may indicate a problem with ArduinoCI, or your configuration", true, &block)
end

def assure_multiline(message, &block)
  perform_action(message, true, @passfail, "This may indicate a problem with ArduinoCI, or your configuration", true, &block)
end

def inform(message, &block)
  perform_action(message, false, proc { |x| x }, nil, false, &block)
end

def inform_multiline(message, &block)
  perform_action(message, true, nil, nil, false, &block)
end

# Assure that a platform exists and return its definition
def assured_platform(purpose, name, config)
  platform_definition = config.platform_definition(name)
  assure("Requested #{purpose} platform '#{name}' is defined in 'platforms' YML") do
    !platform_definition.nil?
  end
  platform_definition
end

# initialize command and config
config = ArduinoCI::CIConfig.default.from_project_library
@arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!

# initialize library under test
installed_library_path = attempt("Installing library under test") do
  @arduino_cmd.install_local_library(Pathname.new("."))
end
if installed_library_path.exist?
  inform("Library installed at") { installed_library_path.to_s }
else
  assure_multiline("Library installed successfully") do
    @arduino_cmd.lib_dir.ascend do |path_part|
      next unless path_part.exist?

      break puts path_part.find.to_a.to_s
    end
    false
  end
end
library_examples = @arduino_cmd.library_examples(installed_library_path)
cpp_library = ArduinoCI::CppLibrary.new(installed_library_path, @arduino_cmd.lib_dir)

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
end

# gather up all required boards so we can install them up front.
# start with the "platforms to unittest" and add the examples
# while we're doing that, get the aux libraries as well
all_platforms = {}
aux_libraries = Set.new(config.aux_libraries_for_unittest + config.aux_libraries_for_build)
# while collecting the platforms, ensure they're defined
config.platforms_to_unittest.each { |p| all_platforms[p] = assured_platform("unittest", p, config) }
library_examples.each do |path|
  ovr_config = config.from_example(path)
  ovr_config.platforms_to_build.each { |p| all_platforms[p] = assured_platform("library example", p, config) }
  aux_libraries.merge(ovr_config.aux_libraries_for_build)
end

# with all platform info, we can extract unique packages and their urls
# do that, set the URLs, and download the packages
all_packages = all_platforms.values.map { |v| v[:package] }.uniq.reject(&:nil?)
all_urls = all_packages.map { |p| config.package_url(p) }.uniq.reject(&:nil?)
unless all_urls.empty?
  assure("Setting board manager URLs") do
    @arduino_cmd.set_pref("boardsmanager.additional.urls", all_urls.join(","))
  end
end

all_packages.each do |p|
  assure("Installing board package #{p}") do
    @arduino_cmd.install_boards(p)
  end
end

aux_libraries.each do |l|
  if @arduino_cmd.library_present?(l)
    inform("Using pre-existing library") { l.to_s }
  else
    assure("Installing aux library '#{l}'") { @arduino_cmd.install_library(l) }
  end
end

# iterate boards / tests
last_board = nil
if !cpp_library.tests_dir.exist?
  inform_multiline("Skipping unit tests; no tests dir at #{cpp_library.tests_dir}") do
    puts cpp_library.tests_dir.find.to_a.to_s
    true
  end
elsif cpp_library.test_files.empty?
  inform_multiline("Skipping unit tests; no test files were found in #{cpp_library.tests_dir}") do
    puts cpp_library.tests_dir.find.to_a.to_s
    true
  end
elsif config.platforms_to_unittest.empty?
  inform("Skipping unit tests") { "no platforms were requested" }
else
  config.platforms_to_unittest.each do |p|
    board = all_platforms[p][:board]
    assure("Switching to board for #{p} (#{board})") { @arduino_cmd.use_board(board) } unless last_board == board
    last_board = board
    cpp_library.test_files.each do |unittest_path|
      unittest_name = unittest_path.basename.to_s
      compilers.each do |gcc_binary|
        attempt_multiline("Unit testing #{unittest_name} with #{gcc_binary}") do
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

if library_examples.empty?
  inform_multiline("Skipping libraries; no examples found in #{installed_library_path}") do
    puts installed_library_path.find.to_a.to_s
  end
else
  attempt("Setting compiler warning level")  { @arduino_cmd.set_pref("compiler.warning_level", "all") }

  # unlike previous, iterate examples / boards
  library_examples.each do |example_path|
    ovr_config = config.from_example(example_path)
    ovr_config.platforms_to_build.each do |p|
      board = all_platforms[p][:board]
      assure("Switching to board for #{p} (#{board})") { @arduino_cmd.use_board(board) } unless last_board == board
      last_board = board
      example_name = File.basename(example_path)
      attempt("Verifying #{example_name}") do
        ret = @arduino_cmd.verify_sketch(example_path)
        unless ret
          puts
          puts "Last command: #{@arduino_cmd.last_msg}"
          puts @arduino_cmd.last_err
        end
        ret
      end
    end
  end
end

terminate(true)
