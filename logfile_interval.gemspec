# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logfile_interval/version'

Gem::Specification.new do |spec|
  spec.name          = "logfile_interval"
  spec.version       = LogfileInterval::VERSION
  spec.authors       = ["Philippe Le Rohellec"]
  spec.email         = ["philippe@lerohellec.com"]
  spec.description   = "Logfile parser and aggregator"
  spec.summary       = "Aggregate logfile data into intervals"
  spec.homepage      = "https://github.com/plerohellec/logfile_interval"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "debugger", [">= 0"]
  spec.add_development_dependency "rspec", ["~> 2.14.0"]
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov"
end
