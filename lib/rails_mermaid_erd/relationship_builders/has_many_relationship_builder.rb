# frozen_string_literal: true

require_relative "base_relationship_builder"

module RailsMermaidErd
  module RelationshipBuilders
    class HasManyRelationshipBuilder < BaseRelationshipBuilder
      def build(model, assoc, models)
        from_table = model.table_name
        fk = safe_foreign_key(model, assoc)
        
        # Skip if we couldn't determine the foreign key
        return [] unless fk
        
        to_table_info = resolve_association_model(model, assoc)

        if to_table_info
          # FK is on target table for has_many
          [Relationship.new(
            to_table_info[:table_name], from_table, fk, "}o--||",
            "#{to_table_info[:table_name]}.#{fk} FK → #{from_table}.#{model.primary_key} PK"
          )]
        else
          log_missing_table_warning(model, assoc)
        end
      end
    end
  end
end 