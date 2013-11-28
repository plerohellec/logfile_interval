# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logfile_interval/version'

Gem::Specification.new do |spec|
  spec.name          = "logfile_interval"
  spec.version       = LogfileInterval::VERSION
  spec.authors       = ["Philippe Le Rohellec"]
  spec.email         = ["philippe@lerohellec.com"]
  spec.description   = %q{Logfile parser and aggregator}
  spec.summary       = %q{Aggregate logfile data into intervals}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency(%q<debugger>, [">= 0"])
  spec.add_development_dependency(%q<rspec>, ["~> 2.14.0"])
  spec.add_development_dependency "rake"
end
