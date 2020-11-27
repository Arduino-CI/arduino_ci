require 'simplecov'
SimpleCov.start do
  add_filter %r{^/spec/}
end
require "bundler/setup"
require "arduino_ci"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def skip_ruby_tests
  !ENV["ARDUINO_CI_SKIP_RUBY_RSPEC_TESTS"].nil?
end

def skip_cpp_tests
  !ENV["ARDUINO_CI_SKIP_CPP_RSPEC_TESTS"].nil?
end
