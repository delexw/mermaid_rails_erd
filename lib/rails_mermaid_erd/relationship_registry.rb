# frozen_string_literal: true

require_relative "relationship_builders/belongs_to_relationship_builder"
require_relative "relationship_builders/has_many_relationship_builder"
require_relative "relationship_builders/has_one_relationship_builder"
require_relative "relationship_builders/habtm_relationship_builder"
require_relative "model_data_collector"

module RailsMermaidErd
  class RelationshipRegistry
    attr_reader :builders, :polymorphic_resolver, :model_data_collector

    def initialize(
      symbol_mapper:,
      association_resolver:,
      polymorphic_resolver:,
      model_data_collector:,
      printed_tables: Set.new
    )
      @polymorphic_resolver = polymorphic_resolver
      @model_data_collector = model_data_collector
      @printed_tables = printed_tables

      @builders = {
        belongs_to: RelationshipBuilders::BelongsToRelationshipBuilder.new(
          symbol_mapper: symbol_mapper,
          association_resolver: association_resolver,
          model_data_collector: model_data_collector,
        ),
        has_many: RelationshipBuilders::HasManyRelationshipBuilder.new(
          symbol_mapper: symbol_mapper,
          association_resolver: association_resolver,
          model_data_collector: model_data_collector,
        ),
        has_one: RelationshipBuilders::HasOneRelationshipBuilder.new(
          symbol_mapper: symbol_mapper,
          association_resolver: association_resolver,
          model_data_collector: model_data_collector,
        ),
        has_and_belongs_to_many: RelationshipBuilders::HasAndBelongsToManyRelationshipBuilder.new(
          symbol_mapper: symbol_mapper,
          association_resolver: association_resolver,
          printed_tables: printed_tables,
          model_data_collector: model_data_collector,
        ),
      }
    end

    def build_relationships(model, assoc)
      # Check for polymorphic association first
      if assoc.options[:polymorphic]
        from_table = model.table_name
        rel_type = builders[assoc.macro].symbol_mapper.map(assoc.macro)
        return polymorphic_resolver.resolve(assoc.name.to_s, from_table, rel_type)
      end

      # Delegate to the appropriate builder
      builder = builders[assoc.macro]
      return builder.build(model, assoc) if builder

      # If no builder exists for this macro type, return an empty array
      []
    end

    def build_all_relationships
      relationships = []

      # Process polymorphic associations first
      @model_data_collector.polymorphic_associations.each do |data|
        model = data[:model]
        assoc = data[:association]
        relationships.concat(build_relationships(model, assoc))
      end

      # Then process regular associations
      @model_data_collector.regular_associations.each do |data|
        model = data[:model]
        assoc = data[:association]
        relationships.concat(build_relationships(model, assoc))
      end

      relationships
    end
  end
end
