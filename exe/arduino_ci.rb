#!/usr/bin/env ruby
require 'arduino_ci'
require 'set'
require 'pathname'
require 'optparse'

WIDTH = 80
FIND_FILES_INDENT = 4

@failure_count = 0
@passfail = proc { |result| result ? "✓" : "✗" }

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

      opts.on("--skip-compilation", "Don't compile example sketches (deprecated)") do |p|
        puts "The option --skip-compilation has been deprecated in favor of --skip-examples-compilation"
        output_options[:skip_compilation] = p
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
  STDOUT.flush
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
FAILED_ASSURANCE_MESSAGE = "This may indicate a problem with ArduinoCI, or your configuration".freeze
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

# Assure that a platform exists and return its definition
def assured_platform(purpose, name, config)
  platform_definition = config.platform_definition(name)
  assure("Requested #{purpose} platform '#{name}' is defined in 'platforms' YML") do
    !platform_definition.nil?
  end
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
  realpath = pathname.symlink? ? pathname.readlink : pathname

  # suppress directories and dotfile-based things
  all_files = realpath.find.select(&:file?)
  non_hidden = all_files.reject { |path| file_is_hidden_somewhere?(path) }

  # print files with an indent
  margin = " " * FIND_FILES_INDENT
  non_hidden.each { |p| puts "#{margin}#{p}" }
end

def install_arduino_library_dependencies(aux_libraries)
  aux_libraries.each do |l|
    if @arduino_cmd.library_present?(l)
      inform("Using pre-existing library") { l.to_s }
    else
      assure("Installing aux library '#{l}'") { @arduino_cmd.install_library(l) }
    end
  end
end

def perform_unit_tests(file_config)
  if @cli_options[:skip_unittests]
    inform("Skipping unit tests") { "as requested via command line" }
    return
  end
  config = file_config.with_override_config(@cli_options[:ci_config])
  cpp_library = ArduinoCI::CppLibrary.new(Pathname.new("."),
                                          @arduino_cmd.lib_dir,
                                          config.exclude_dirs.map(&Pathname.method(:new)))

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

  # Ensure platforms exist for unit test, and save their info in all_platform_info keyed by name
  all_platform_info = {}
  config.platforms_to_unittest.each { |p| all_platform_info[p] = assured_platform("unittest", p, config) }

  inform("Library conforms to Arduino library specification") { cpp_library.one_point_five? ? "1.5" : "1.0" }

  # iterate boards / tests
  if !cpp_library.tests_dir.exist?
    inform_multiline("Skipping unit tests; no tests dir at #{cpp_library.tests_dir}") do
      puts "  In case that's an error, this is what was found in the library:"
      display_files(cpp_library.tests_dir.parent)
      true
    end
  elsif cpp_library.test_files.empty?
    inform_multiline("Skipping unit tests; no test files were found in #{cpp_library.tests_dir}") do
      puts "  In case that's an error, this is what was found in the tests directory:"
      display_files(cpp_library.tests_dir)
      true
    end
  elsif config.platforms_to_unittest.empty?
    inform("Skipping unit tests") { "no platforms were requested" }
  else
    install_arduino_library_dependencies(config.aux_libraries_for_unittest)

    config.platforms_to_unittest.each do |p|
      config.allowable_unittest_files(cpp_library.test_files).each do |unittest_path|
        unittest_name = unittest_path.basename.to_s
        compilers.each do |gcc_binary|
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
end

def perform_compilation_tests(config)
  if @cli_options[:skip_compilation]
    inform("Skipping compilation of examples") { "as requested via command line" }
    return
  end

  # index the existing libraries
  attempt("Indexing libraries") { @arduino_cmd.index_libraries } unless @arduino_cmd.libraries_indexed

  # initialize library under test
  installed_library_path = attempt("Installing library under test") do
    @arduino_cmd.install_local_library(Pathname.new("."))
  end

  if !installed_library_path.nil? && installed_library_path.exist?
    inform("Library installed at") { installed_library_path.to_s }
  else
    assure_multiline("Library installed successfully") do
      if installed_library_path.nil?
        puts @arduino_cmd.last_msg
      else
        # print out the contents of the deepest directory we actually find
        @arduino_cmd.lib_dir.ascend do |path_part|
          next unless path_part.exist?

          break display_files(path_part)
        end
        false
      end
    end
  end
  library_examples = @arduino_cmd.library_examples(installed_library_path)

  # gather up all required boards for compilation so we can install them up front.
  # start with the "platforms to unittest" and add the examples
  # while we're doing that, get the aux libraries as well
  example_platform_info = {}
  board_package_url = {}
  aux_libraries = Set.new(config.aux_libraries_for_build)
  # while collecting the platforms, ensure they're defined

  library_examples.each do |path|
    ovr_config = config.from_example(path)
    ovr_config.platforms_to_build.each do |platform|
      # assure the platform if we haven't already
      next if example_platform_info.key?(platform)

      platform_info = assured_platform("library example", platform, config)
      next if platform_info.nil?

      example_platform_info[platform] = platform_info
      package = platform_info[:package]
      board_package_url[package] = ovr_config.package_url(package)
    end
    aux_libraries.merge(ovr_config.aux_libraries_for_build)
  end

  # with all platform info, we can extract unique packages and their urls
  # do that, set the URLs, and download the packages
  all_packages = example_platform_info.values.map { |v| v[:package] }.uniq.reject(&:nil?)

  # inform about builtin packages
  all_packages.select { |p| config.package_builtin?(p) }.each do |p|
    inform("Using built-in board package") { p }
  end

  # make sure any non-builtin package has a URL defined
  all_packages.reject { |p| config.package_builtin?(p) }.each do |p|
    assure("Board package #{p} has a defined URL") { board_package_url[p] }
  end

  # set up all the board manager URLs.
  # we can safely reject nils now, they would be for the builtins
  all_urls = all_packages.map { |p| board_package_url[p] }.uniq.reject(&:nil?)

  unless all_urls.empty?
    assure("Setting board manager URLs") do
      @arduino_cmd.board_manager_urls = all_urls
    end
  end

  all_packages.each do |p|
    assure("Installing board package #{p}") do
      @arduino_cmd.install_boards(p)
    end
  end

  install_arduino_library_dependencies(aux_libraries)

  last_board = nil
  if config.platforms_to_build.empty?
    inform("Skipping builds") { "no platforms were requested" }
    return
  elsif library_examples.empty?
    inform_multiline("Skipping builds; no examples found in #{installed_library_path}") do
      display_files(installed_library_path)
    end
    return
  end

  attempt("Setting compiler warning level")  { @arduino_cmd.set_pref("compiler.warning_level", "all") }

  # switching boards takes time, so iterate board first
  # _then_ whichever examples match it
  examples_by_platform = library_examples.each_with_object({}) do |example_path, acc|
    ovr_config = config.from_example(example_path)
    ovr_config.platforms_to_build.each do |p|
      acc[p] = [] unless acc.key?(p)
      acc[p] << example_path
    end
  end

  examples_by_platform.each do |platform, example_paths|
    board = example_platform_info[platform][:board]
    assure("Switching to board for #{platform} (#{board})") { @arduino_cmd.use_board(board) } unless last_board == board
    last_board = board

    example_paths.each do |example_path|
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

# initialize command and config
config = ArduinoCI::CIConfig.default.from_project_library

@arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!
inform("Located Arduino binary") { @arduino_cmd.binary_path.to_s }

perform_unit_tests(config)
perform_compilation_tests(config)

terminate(true)
