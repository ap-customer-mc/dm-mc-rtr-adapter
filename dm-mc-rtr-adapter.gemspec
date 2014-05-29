# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dm-mc-rtr-adapter/version'

Gem::Specification.new do |spec|
  spec.name          = "dm-mc-rtr-adapter"
  spec.version       = SoapAdapter::VERSION
  spec.authors       = ["AnyPresence"]
  spec.email         = ["info@anypresence.com"]
  spec.summary       = "DM adapter for SOAP based data sources."
  spec.homepage      = "https://github.com/AnyPresence/dm-mc-rtr-adapter"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_dependency "httpclient",     "~> 2.1.5.2"
  spec.add_dependency "data_objects",   "~> 0.10.13"
  spec.add_dependency "git://github.com/AnyPresence-Services/signer.git"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
