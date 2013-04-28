# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dm/soap/adapter/version'

Gem::Specification.new do |spec|
  spec.name          = "dm-soap-adapter"
  spec.version       = Dm::Soap::Adapter::VERSION
  spec.authors       = ["Brandon Cox"]
  spec.email         = ["bcox@anypresence.com"]
  spec.summary       = "DM adapter for SOAP based data sources."
  spec.description   = s.summary
  spec.homepage      = "https://github.com/AnyPresence/dm-soap-adapter"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
