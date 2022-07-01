g++ -v
cd SampleProjects/SharedLibrary
bundle install
bundle exec ensure_arduino_installation.rb
bundle exec arduino_ci.rb --skip-examples-compilation
echo status=$?
echo "Status = $status"
if [ $status -ne 1 ]; then
  exit 1
fi
exit 0
