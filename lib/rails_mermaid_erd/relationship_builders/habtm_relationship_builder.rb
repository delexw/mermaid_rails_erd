# frozen_string_literal: true

require_relative "base_relationship_builder"
require_relative "../relationship"

module RailsMermaidErd
  module RelationshipBuilders
    class HasAndBelongsToManyRelationshipBuilder < BaseRelationshipBuilder
      def initialize(symbol_mapper:, association_resolver:, printed_tables: Set.new)
        super(symbol_mapper: symbol_mapper, association_resolver: association_resolver)
        @printed_tables = printed_tables
      end

      def build(model, assoc, models)
        from_table = model.table_name
        to_table_info = resolve_association_model(model, assoc)
        
        if !to_table_info
          return log_missing_table_warning(model, assoc, "target model does not exist")
        end
        
        join_table = assoc.join_table.to_s
        
        # Check if we need to verify the table existence
        unless @printed_tables.include?(join_table)
          begin
            ActiveRecord::Base.connection.columns(join_table)
            @printed_tables << join_table
          rescue => e
            return log_missing_table_warning(model, assoc, "join table #{join_table} is missing: #{e.message}")
          end
        end
        
        # Try to get the foreign keys
        source_fk = nil
        target_fk = nil
        
        begin
          source_fk = assoc.foreign_key
        rescue => e
          puts "  WARNING: Could not determine foreign key for #{model.name} in HABTM: #{e.message}"
        end
        
        begin
          target_fk = assoc.association_foreign_key
        rescue => e
          puts "  WARNING: Could not determine association foreign key for #{model.name}##{assoc.name}: #{e.message}"
        end
        
        # Skip if we couldn't determine both foreign keys
        if !source_fk || !target_fk
          return log_missing_table_warning(model, assoc, "could not determine foreign keys")
        end
        
        # If we reach here, the join table exists, so create relationships
        [
          Relationship.new(
            join_table, 
            from_table, 
            source_fk, 
            "}o--||",
            nil, # Let the Relationship generate the label
            join_table, # fk_table
            source_fk, # fk_column
            from_table, # pk_table
            model.primary_key # pk_column
          ),
          Relationship.new(
            join_table, 
            to_table_info[:table_name], 
            target_fk, 
            "}o--||",
            nil, # Let the Relationship generate the label
            join_table, # fk_table
            target_fk, # fk_column
            to_table_info[:table_name], # pk_table
            to_table_info[:primary_key] # pk_column
          )
        ]
      end
    end
  end
end 