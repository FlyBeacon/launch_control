# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'launch_control/version'

Gem::Specification.new do |spec|
  spec.name          = "launch_control"
  spec.version       = LaunchControl::VERSION
  spec.authors       = ["Chris Teague"]
  spec.email         = ["chris@cteague.com.au"]

  spec.summary       = %q{Ensure that emails delivered to Mandrill meet a specified contract.}
  spec.homepage      = "https://flybeacon.com/"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mandrill-api", '~> 1.0', ">= 1.0.53"
  spec.add_dependency "hash_validator", '~> 0.4', ">= 0.4.0"
  spec.add_dependency "activesupport", ">= 3.2.13"

  spec.add_development_dependency "bundler", ">= 1.10"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec", '~> 3.2', ">= 3.2.0"
  spec.add_development_dependency "pry", '~> 0.9', ">= 0.9.12"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "simplecov", '~> 0.10', ">= 0.10.0"
end
