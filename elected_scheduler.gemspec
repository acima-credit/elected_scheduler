# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elected/scheduler/version'

Gem::Specification.new do |spec|
  spec.name          = "elected_scheduler"
  spec.version       = Elected::Scheduler::VERSION
  spec.authors       = ["Adrian Madrid"]
  spec.email         = ["aemadrid@gmail.com"]

  spec.summary       = %q{Run code blocks at selected times on leader processes.}
  spec.description   = %q{Run code blocks at scheduled times (secods, minutes, hours, etc.) only on elected leader processes.}
  spec.homepage      = "https://github.com/simple-finance/elected_shceduler"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'elected', '0.1.0'
  spec.add_dependency 'pry'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'timecop'
end
