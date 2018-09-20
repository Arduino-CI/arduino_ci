require 'arduino_ci/arduino_cmd'
require 'timeout'

module ArduinoCI

  # Implementation of Arduino linux IDE commands
  class ArduinoCmdLinux < ArduinoCmd
    flag :get_pref,        "--get-pref"
    flag :set_pref,        "--pref"
    flag :save_prefs,      "--save-prefs"
    flag :use_board,       "--board"
    flag :install_boards,  "--install-boards"
    flag :install_library, "--install-library"
    flag :verify,          "--verify"
  end

end
