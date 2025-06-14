# frozen_string_literal: true

require_relative "relationship"
require_relative "mermaid_emitter"
require_relative "column_info"
require_relative "model_loader"
require_relative "association_resolver"
require_relative "polymorphic_targets_resolver"
require_relative "relationship_symbol_mapper"
require_relative "relationship_registry"
require_relative "table_collector"
require_relative "relationship_builders/base_relationship_builder"

module RailsMermaidErd
  class Generator
    def initialize(output:)
      @output = output
      @printed_tables = Set.new
      @printed_relationships = Set.new
      
      @model_loader = ModelLoader.new
      @association_resolver = AssociationResolver.new
      @symbol_mapper = RelationshipSymbolMapper.new
      @polymorphic_resolver = PolymorphicTargetsResolver.new
      @table_collector = TableCollector.new
      @relationship_registry = RelationshipRegistry.new(
        symbol_mapper: @symbol_mapper,
        association_resolver: @association_resolver,
        polymorphic_resolver: @polymorphic_resolver,
        printed_tables: @printed_tables
      )
    end

    def generate
      models = @model_loader.load
      tables = @table_collector.collect_tables(models)
      relationships = []

      # First pass: collect tables and build relationships
      models.each do |model|
        begin
          next if model < model.base_class || !model.table_exists?

          model.reflect_on_all_associations.each do |assoc|
            begin
              relationships += @relationship_registry.build_relationships(model, assoc, models)
            rescue => e
              puts "ERROR processing association #{model.name}##{assoc.name}: #{e.class} - #{e.message}"
              puts e.backtrace.join("\n")
            end
          end
        rescue => e
          puts "ERROR processing model #{model.name}: #{e.class} - #{e.message}"
          puts e.backtrace.join("\n")
        end
      end
      
      # Second pass: update table definitions with FK annotations
      tables = @table_collector.update_foreign_keys(tables, relationships)

      MermaidEmitter.new(@output, tables, relationships).emit
    end
  end
end 