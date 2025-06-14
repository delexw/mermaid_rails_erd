# frozen_string_literal: true

require_relative "lib/rails_mermaid_erd/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_mermaid_erd"
  spec.version       = RailsMermaidErd::VERSION
  spec.authors       = ["Yang Liu"]
  spec.email         = ["adamyoungliu@gmail.com"]

  spec.summary       = "Generate Mermaid.js Entity Relationship Diagrams from ActiveRecord models"
  spec.description   = "A Ruby gem that introspects ActiveRecord models and generates Mermaid.js ERD syntax for visualizing database relationships in Rails applications."
  spec.homepage      = "https://github.com/delexw/rails_mermaid_erd"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/delexw/rails_mermaid_erd"
  spec.metadata["changelog_uri"] = "https://github.com/delexw/rails_mermaid_erd/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{lib,bin}/**/*") + Dir.glob("lib/tasks/**/*.rake") + %w[
    README.md
    Rakefile
    rails_mermaid_erd.gemspec
  ]
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "activerecord", ">= 3.0"
  spec.add_dependency "activesupport", ">= 3.0"
  spec.add_dependency "railties", ">= 3.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end 