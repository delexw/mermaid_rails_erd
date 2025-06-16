# frozen_string_literal: true

require_relative "rails_mermaid_erd/version"
require_relative "rails_mermaid_erd/generator"
require_relative "rails_mermaid_erd/relationship"
require_relative "rails_mermaid_erd/mermaid_emitter"
require_relative "rails_mermaid_erd/column_info"
require_relative "rails_mermaid_erd/model_loader"
require_relative "rails_mermaid_erd/association_resolver"
require_relative "rails_mermaid_erd/polymorphic_targets_resolver"
require_relative "rails_mermaid_erd/relationship_symbol_mapper"
require_relative "rails_mermaid_erd/relationship_registry"
require_relative "rails_mermaid_erd/model_data_collector"
require_relative "rails_mermaid_erd/relationship_builders/base_relationship_builder"
require_relative "rails_mermaid_erd/relationship_builders/belongs_to_relationship_builder"
require_relative "rails_mermaid_erd/relationship_builders/has_many_relationship_builder"
require_relative "rails_mermaid_erd/relationship_builders/has_one_relationship_builder"
require_relative "rails_mermaid_erd/relationship_builders/habtm_relationship_builder"
require_relative "rails_mermaid_erd/railtie" if defined?(Rails)

module RailsMermaidErd
  class Error < StandardError; end

  # Generate Mermaid ERD and write to output stream
  # @param output [IO] Output stream to write the ERD to
  def self.generate(output: $stdout)
    Generator.new(output: output).generate
  end
end 