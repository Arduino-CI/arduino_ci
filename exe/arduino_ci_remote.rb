#!/usr/bin/env ruby
require 'arduino_ci'
require 'set'

WIDTH = 80

@failure_count = 0

# terminate after printing any debug info.  TODO: capture debug info
def terminate
  puts "Failures: #{@failure_count}"
  unless @failure_count.zero?
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
def perform_action(message, on_fail_msg, abort_on_fail)
  line = "#{message}..."
  print line
  result = yield
  mark = result ? "✓" : "X"
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
  perform_action(message, nil, false, &block)
end

# Make a nice status for something that kills the script immediately on failure
def assure(message, &block)
  perform_action(message, "This may indicate a problem with ArduinoCI!", true, &block)
end

# initialize command and config
config = ArduinoCI::CIConfig.default.from_project_library
@arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!

# initialize library under test
installed_library_path = assure("Installing library under test") { @arduino_cmd.install_local_library(".") }
library_examples = @arduino_cmd.library_examples(installed_library_path)
cpp_library = ArduinoCI::CppLibrary.new(installed_library_path)

# gather up all required boards so we can install them up front.
# start with the "platforms to unittest" and add the examples
# while we're doing that, get the aux libraries as well
all_platforms = {}
aux_libraries = Set.new(config.aux_libraries_for_unittest + config.aux_libraries_for_build)
config.platforms_to_unittest.each { |p| all_platforms[p] = config.platform_definition(p) }
library_examples.each do |path|
  ovr_config = config.from_example(path)
  ovr_config.platforms_to_build.each { |p| all_platforms[p] = config.platform_definition(p) }
  aux_libraries.merge(ovr_config.aux_libraries_for_build)
end

# with all platform info, we can extract unique packages and their urls
# do that, set the URLs, and download the packages
all_packages = all_platforms.values.map { |v| v[:package] }.uniq.reject(&:nil?)
all_urls = all_packages.map { |p| config.package_url(p) }.uniq.reject(&:nil?)
assure("Setting board manager URLs") do
  @arduino_cmd.set_pref("boardsmanager.additional.urls", all_urls.join(","))
end

all_packages.each do |p|
  assure("Installing board package #{p}") do
    @arduino_cmd.install_boards(p)
  end
end

aux_libraries.each do |l|
  assure("Installing aux library '#{l}'") { @arduino_cmd.install_library(l) }
end

attempt("Setting compiler warning level") { @arduino_cmd.set_pref("compiler.warning_level", "all") }

library_examples.each do |example_path|
  ovr_config = config.from_example(example_path)
  ovr_config.platforms_to_build.each do |p|
    board = all_platforms[p][:board]
    assure("Switching to board for #{p} (#{board})") { @arduino_cmd.use_board(board) }
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

config.platforms_to_unittest.each do |p|
  board = all_platforms[p][:board]
  assure("Switching to board for #{p} (#{board})") { @arduino_cmd.use_board(board) }
  cpp_library.test_files.each do |unittest_path|
    unittest_name = File.basename(unittest_path)
    attempt("Unit testing #{unittest_name}") do
      exe = cpp_library.build_for_test_with_configuration(
        unittest_path,
        config.aux_libraries_for_unittest,
        config.gcc_config(p)
      )
      unless exe
        puts
        puts "Last command: #{cpp_library.last_cmd}"
        puts cpp_library.last_out
        puts cpp_library.last_err
        next false
      end
      cpp_library.run_test_file(exe)
    end
  end
end

terminate
