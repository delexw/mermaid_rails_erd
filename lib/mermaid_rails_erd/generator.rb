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
require_relative "parsed_data"

module MermaidRailsErd
  class Generator
    def initialize(output: nil)
      @output = output
      @printed_tables = Set.new
      @printed_relationships = Set.new
      @relationships = []

      @model_loader = ModelLoader.new
      @association_resolver = AssociationResolver.new
      @symbol_mapper = RelationshipSymbolMapper.new
      @model_data_collector = ModelDataCollector.new(@model_loader)
      @polymorphic_resolver = PolymorphicTargetsResolver.new(@model_data_collector)
      @relationship_registry = RelationshipRegistry.new(
        symbol_mapper: @symbol_mapper,
        association_resolver: @association_resolver,
        polymorphic_resolver: @polymorphic_resolver,
        printed_tables: @printed_tables,
        model_data_collector: @model_data_collector,
      )
    end

    # Build and collect data from models
    # @return [self]
    def build
      @model_data_collector.collect

      # Build all relationships with polymorphic handling first
      begin
        @relationships = @relationship_registry.build_all_relationships
      rescue StandardError => e
        puts "ERROR building relationships: #{e.class} - #{e.message}"
        puts e.backtrace.join("\n")
        @relationships = []
      end

      # Update table definitions with FK annotations
      @tables = @model_data_collector.update_foreign_keys(@relationships)

      self
    end

    # Get parsed data as a structured object
    # @return [ParsedData] Struct containing relationships, tables, and delegated model data
    def parsed_data
      ParsedData.new(@relationships, @tables, @model_data_collector)
    end

    # Generate and emit the ERD diagram
    # @param output [IO] Output stream to write the ERD to (defaults to the one provided in initialize)
    # @return [void]
    def emit(output: nil)
      output ||= @output
      output ||= $stdout
      MermaidEmitter.new(output, @tables, @relationships).emit
    end
  end
end
