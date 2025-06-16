# frozen_string_literal: true

require_relative "relationship_builders/belongs_to_relationship_builder"
require_relative "relationship_builders/has_many_relationship_builder"
require_relative "relationship_builders/has_one_relationship_builder"
require_relative "relationship_builders/habtm_relationship_builder"
require_relative "model_data_collector"

module RailsMermaidErd
  class RelationshipRegistry
    attr_reader :builders, :polymorphic_resolver, :model_data_collector

    def initialize(symbol_mapper:, association_resolver:, polymorphic_resolver:, printed_tables: Set.new)
      @polymorphic_resolver = polymorphic_resolver
      # We will use the same model_data_collector that's provided via the polymorphic_resolver
      @model_data_collector = polymorphic_resolver.model_data_collector
      
      @builders = {
        belongs_to: RelationshipBuilders::BelongsToRelationshipBuilder.new(
          symbol_mapper: symbol_mapper, 
          association_resolver: association_resolver
        ),
        has_many: RelationshipBuilders::HasManyRelationshipBuilder.new(
          symbol_mapper: symbol_mapper, 
          association_resolver: association_resolver
        ),
        has_one: RelationshipBuilders::HasOneRelationshipBuilder.new(
          symbol_mapper: symbol_mapper, 
          association_resolver: association_resolver
        ),
        has_and_belongs_to_many: RelationshipBuilders::HasAndBelongsToManyRelationshipBuilder.new(
          symbol_mapper: symbol_mapper, 
          association_resolver: association_resolver,
          printed_tables: printed_tables
        )
      }
    end

    def build_relationships(model, assoc, models)
      # Check for polymorphic association first
      if assoc.options[:polymorphic]
        from_table = model.table_name
        rel_type = builders[assoc.macro].symbol_mapper.map(assoc.macro)
        return polymorphic_resolver.resolve(assoc.name.to_s, from_table, rel_type, models)
      end
      
      # Delegate to the appropriate builder
      builder = builders[assoc.macro]
      return builder.build(model, assoc, models) if builder
      
      # If no builder exists for this macro type, return an empty array
      []
    end
    
    def build_all_relationships(models)
      relationships = []
      
      # Process polymorphic associations first
      @model_data_collector.polymorphic_associations.each do |data|
        model = data[:model]
        assoc = data[:association]
        relationships.concat(build_relationships(model, assoc, models))
      end
      
      # Then process regular associations
      @model_data_collector.regular_associations.each do |data|
        model = data[:model]
        assoc = data[:association]
        relationships.concat(build_relationships(model, assoc, models))
      end
      
      relationships
    end
  end
end 