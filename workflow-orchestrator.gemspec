# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'workflow/version'

Gem::Specification.new do |gem|
  gem.name          = "workflow-orchestrator"
  gem.version       = Workflow::VERSION
  gem.authors       = ["Lorefnon"]
  gem.email         = ["lorefnon@gmail.com"]
  gem.description   = <<DOC
A ruby DSL for modeling business logic as Finite State Machines.

The aim of this library is to make the expression of these concepts as clear as possible, utilizing the expressiveness of ruby language, and using similar terminology as found in state machine theory.
DOC
  gem.summary       = "A ruby DSL for modeling business logic as Finite State Machines"
  gem.homepage      = "https://github.com/lorefnon/workflow-orchestrator"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.extra_rdoc_files = [
    "README.md"
  ]

  gem.add_development_dependency 'rdoc',    [">= 3.12"]
  gem.add_development_dependency 'bundler', [">= 1.0.0"]
  gem.add_development_dependency 'activerecord'
  gem.add_development_dependency 'protected_attributes'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'test-unit'
  gem.add_development_dependency 'pry-rails'
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'ruby-graphviz', ['~> 1.0.0']
  
  gem.required_ruby_version = '>= 2.0.0'
end

