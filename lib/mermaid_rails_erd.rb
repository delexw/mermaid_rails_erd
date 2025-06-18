# frozen_string_literal: true

require_relative "mermaid_rails_erd/version"
require_relative "mermaid_rails_erd/generator"
require_relative "mermaid_rails_erd/relationship"
require_relative "mermaid_rails_erd/mermaid_emitter"
require_relative "mermaid_rails_erd/column_info"
require_relative "mermaid_rails_erd/model_loader"
require_relative "mermaid_rails_erd/association_resolver"
require_relative "mermaid_rails_erd/polymorphic_targets_resolver"
require_relative "mermaid_rails_erd/relationship_symbol_mapper"
require_relative "mermaid_rails_erd/relationship_registry"
require_relative "mermaid_rails_erd/model_data_collector"
require_relative "mermaid_rails_erd/relationship_builders/base_relationship_builder"
require_relative "mermaid_rails_erd/relationship_builders/belongs_to_relationship_builder"
require_relative "mermaid_rails_erd/relationship_builders/has_many_relationship_builder"
require_relative "mermaid_rails_erd/relationship_builders/has_one_relationship_builder"
require_relative "mermaid_rails_erd/relationship_builders/habtm_relationship_builder"
require_relative "mermaid_rails_erd/railtie" if defined?(Rails)

module MermaidRailsErd
  class Error < StandardError; end

  # Build and return a Generator instance with all data collected
  # @return [Generator] Generator instance with collected data
  def self.build
    Generator.new.build
  end

  # Generate Mermaid ERD and write to output stream
  # @param output [IO] Output stream to write the ERD to
  def self.generate(output: $stdout)
    build.emit(output: output)
  end
end
