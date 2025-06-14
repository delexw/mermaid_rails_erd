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
        to_model = resolve_association_model(model, assoc)
        
        if !to_model
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
        
        # If we reach here, the join table exists, so create relationships
        [
          Relationship.new(
            join_table, from_table, assoc.foreign_key, "}o--||",
            "#{join_table}.#{assoc.foreign_key} FK → #{from_table}.id PK"),
          Relationship.new(
            join_table, to_model.table_name, assoc.association_foreign_key, "}o--||",
            "#{join_table}.#{assoc.association_foreign_key} FK → #{to_model.table_name}.id PK")
        ]
      end
    end
  end
end 