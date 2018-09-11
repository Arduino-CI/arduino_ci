# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "arduino_ci/version"

Gem::Specification.new do |spec|
  spec.name          = "arduino_ci"
  spec.version       = ArduinoCI::VERSION
  spec.licenses      = ['Apache-2.0']
  spec.authors       = ["Ian Katz"]
  spec.email         = ["ianfixes@gmail.com"]

  spec.summary       = "Tools for building and unit testing Arduino libraries"
  spec.description   = spec.description
  spec.homepage      = "http://github.com/ianfixes/arduino_ci"

  spec.bindir        = "exe"
  rejection_regex    = %r{^(test|spec|features)/}
  libfiles           = Dir['lib/**/*.*'].reject { |f| f.match(rejection_regex) }
  binfiles           = Dir[File.join(spec.bindir, '/**/*.*')].reject { |f| f.match(rejection_regex) }
  cppfiles           = Dir['cpp/**/*.*']
  miscfiles          = Dir['misc/**/*.*']
  spec.files         = ['README.md', '.yardopts'] + libfiles + binfiles + cppfiles + miscfiles

  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "os", "~> 1.0"
  spec.add_dependency "rubyzip", "~> 1.2"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'rubocop', '~>0.59.0'
  spec.add_development_dependency 'yard', '~>0.9.11'
end
