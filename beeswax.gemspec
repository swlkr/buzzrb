# frozen_string_literal: true

require_relative "lib/beeswax/version"

Gem::Specification.new do |spec|
  spec.name    = "beeswax"
  spec.version = Beeswax::VERSION
  spec.authors = ["Letterpress"]
  spec.summary = "Ruby client for the Beeswax/Freewheel Advertiser API v2.0"
  spec.homepage = "https://github.com/getletterpress/beeswaxrb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*.rb"] + ["beeswax.gemspec", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webrick", "~> 1.8"
end
