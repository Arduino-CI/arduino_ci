require 'arduino_ci'

puts "Enabling display with display manager"
ArduinoCI::DisplayManager::instance.enable

puts "Autlocating Arduino command"
arduino_cmd = ArduinoCI::ArduinoCmd.autolocate!

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

abort if got_problem
exit(0)
