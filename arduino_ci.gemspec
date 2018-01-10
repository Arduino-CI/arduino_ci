# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "arduino_ci/version"

Gem::Specification.new do |spec|
  spec.name          = "arduino_ci"
  spec.version       = ArduinoCI::VERSION
  spec.licenses      = ['Apache-2.0']
  spec.authors       = ["Ian Katz"]
  spec.email         = ["ifreecarve@gmail.com"]

  spec.summary       = "Tools for building and unit testing Arduino libraries"
  spec.description   = spec.description
  spec.homepage      = "http://github.com/ifreecarve/arduino_ci"

  spec.files         =  ['README.md', '.yardopts'] + Dir['lib/**/*.*'].reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'rubocop', '~>0.49.0'
  spec.add_development_dependency 'yard', '~>0.9.11'
end
