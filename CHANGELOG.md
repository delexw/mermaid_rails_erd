# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Improved polymorphic relationship discovery using Rails' reflection API
- More robust detection of polymorphic associations without relying on naming patterns
- Added `PolymorphicRelationshipBuilder` class for accurately mapping polymorphic interfaces
- Updated documentation with polymorphic association examples

## [0.1.0] - 2024-01-XX

### Added
- Initial release of Rails Mermaid ERD gem
- ActiveRecord model introspection for ERD generation
- Mermaid.js ERD syntax output
- Support for belongs_to, has_one, has_many, and has_and_belongs_to_many associations
- Rake task for generating ERD diagrams (`rails_mermaid_erd:generate`)
- Column type mapping from ActiveRecord to Mermaid types
- Support for ActiveRecord 3.0 and above
- Comprehensive documentation and examples 