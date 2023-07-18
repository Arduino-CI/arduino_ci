g++ -v
cd SampleProjects/Makefile
bundle install
bundle exec ensure_arduino_installation.rb
bundle exec arduino_ci.rb --skip-examples-compilation
