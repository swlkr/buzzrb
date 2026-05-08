# frozen_string_literal: true

require_relative "lib/buzz/version"

Gem::Specification.new do |spec|
  spec.name    = "buzzrb"
  spec.version = Buzz::VERSION
  spec.authors = ["swlkr"]
  spec.summary = "Ruby client for the Buzz/Freewheel Advertiser API v2.0"
  spec.homepage = "https://github.com/swlkr/buzzrb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*.rb"] + ["buzzrb.gemspec", "LICENSE.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webrick", "~> 1.8"
end
