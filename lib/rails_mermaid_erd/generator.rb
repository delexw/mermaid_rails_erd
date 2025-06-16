# frozen_string_literal: true

require_relative "relationship"
require_relative "mermaid_emitter"
require_relative "column_info"
require_relative "model_loader"
require_relative "association_resolver"
require_relative "polymorphic_targets_resolver"
require_relative "relationship_symbol_mapper"
require_relative "relationship_registry"
require_relative "model_data_collector"

module RailsMermaidErd
  class Generator
    def initialize(output:)
      @output = output
      @printed_tables = Set.new
      @printed_relationships = Set.new
      
      @model_loader = ModelLoader.new
      @association_resolver = AssociationResolver.new
      @symbol_mapper = RelationshipSymbolMapper.new
      @model_data_collector = ModelDataCollector.new
      @polymorphic_resolver = PolymorphicTargetsResolver.new(@model_data_collector)
      @relationship_registry = RelationshipRegistry.new(
        symbol_mapper: @symbol_mapper,
        association_resolver: @association_resolver,
        polymorphic_resolver: @polymorphic_resolver,
        printed_tables: @printed_tables
      )
    end

    def generate
      # Load models
      models = @model_loader.load

      # Collect all model data - this also registers polymorphic targets and collects tables
      filtered_models = models.reject { |model| model < model.base_class || !model.table_exists? }
      @model_data_collector.collect(filtered_models)

      # Build all relationships with polymorphic handling first
      begin
        relationships = @relationship_registry.build_all_relationships(filtered_models)
      rescue => e
        puts "ERROR building relationships: #{e.class} - #{e.message}"
        puts e.backtrace.join("\n")
        relationships = []
      end
      
      # Update table definitions with FK annotations
      tables = @model_data_collector.update_foreign_keys(relationships)

      MermaidEmitter.new(@output, tables, relationships).emit
    end
  end
end 