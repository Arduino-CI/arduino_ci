require 'arduino_ci'

puts "Autlocating Arduino command"
arduino_cmd = ArduinoCI::ArduinoInstallation.autolocate!

board_tests = {
  "arduino:avr:uno" => true,
  "eggs:milk:wheat" => false,
}

got_problem = false
board_tests.each do |k, v|
  puts "I expect arduino_cmd.board_installed?(#{k}) to be #{v}"
  result = arduino_cmd.board_installed?(k)
  puts "  board_installed?(#{k}) returns #{result}.  expected #{v}"
  got_problem = true if v != result
end

urls = [
  "https://adafruit.github.io/arduino-board-index/package_adafruit_index.json",
  "http://arduino.esp8266.com/stable/package_esp8266com_index.json"
]

puts "Setting additional URLs"
got_problem = true unless arduino_cmd.set_pref("boardsmanager.additional.urls", urls.join(","))

puts "Installing arduino:sam"
got_problem = true unless arduino_cmd.install_board("arduino:sam")
puts "Installing USBHost"
got_problem = true unless arduino_cmd.install_library("USBHost")
puts "checking that library is indexed"
got_problem = true unless arduino_cmd.library_is_indexed

my_board = "arduino:sam:arduino_due_x"

puts "use board! (install board)"
got_problem = true unless arduino_cmd.use_board!(my_board)
puts "assert that board has been installed"
got_problem = true unless arduino_cmd.board_installed?(my_board)

puts "setting compiler warning level"
got_problem = true unless arduino_cmd.set_pref("compiler.warning_level", "all")

simple_sketch = File.join(File.dirname(File.dirname(__FILE__)), "spec", "FakeSketch", "FakeSketch.ino")

puts "verify a simple sketch"
got_problem = true unless arduino_cmd.verify_sketch(simple_sketch)

library_path = File.join(File.dirname(File.dirname(__FILE__)), "SampleProjects", "DoSomething")

puts "verify a library with arduino mocks"
cpp_library = ArduinoCI::CppLibrary.new(library_path)
got_problem = true unless cpp_library.build(arduino_cmd)

puts "verify the examples of a library (#{library_path})..."
puts " - Install the library"
installed_library_path = arduino_cmd.install_local_library(library_path)
got_problem = true if installed_library_path.nil?
puts " - Iterate over the examples"
arduino_cmd.each_library_example(installed_library_path) do |example_path|
  puts "Iterating #{example_path}"
  got_problem = true unless arduino_cmd.verify_sketch(example_path)
end

abort if got_problem
exit(0)
