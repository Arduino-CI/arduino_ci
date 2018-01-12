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

urls = [
  "https://adafruit.github.io/arduino-board-index/package_adafruit_index.json",
  "http://arduino.esp8266.com/stable/package_esp8266com_index.json"
]

result = arduino_cmd.set_pref("boardsmanager.additional.urls", urls.join(","))
got_problem = true unless result

got_problem = true unless arduino_cmd.install_board("arduino:sam")
got_problem = true unless arduino_cmd.install_library("USBHost")
got_problem = true unless arduino_cmd.library_is_indexed

abort if got_problem
exit(0)
