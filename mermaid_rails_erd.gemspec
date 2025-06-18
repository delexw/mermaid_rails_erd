# frozen_string_literal: true

require_relative "lib/mermaid_rails_erd/version"

Gem::Specification.new do |spec|
  spec.name          = "mermaid_rails_erd"
  spec.version       = MermaidRailsErd::VERSION
  spec.authors       = ["YL"]
  spec.email         = ["adamyoungliu@gmail.com"]

  spec.summary       = "Generate Mermaid.js Entity Relationship Diagrams from ActiveRecord models"
  spec.description   = "A Ruby gem that introspects ActiveRecord models and generates Mermaid.js ERD syntax for visualizing database relationships in Rails applications."
  spec.homepage      = "https://github.com/delexw/mermaid_rails_erd"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/delexw/mermaid_rails_erd"
  spec.metadata["changelog_uri"] = "https://github.com/delexw/mermaid_rails_erd/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{lib,bin}/**/*") + Dir.glob("lib/tasks/**/*.rake") + %w[
    README.md
    Rakefile
    mermaid_rails_erd.gemspec
    LICENSE
  ]
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "activerecord", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "railties", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.6"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 3.6.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
