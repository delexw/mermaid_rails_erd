# frozen_string_literal: true

require_relative "base_relationship_builder"

module RailsMermaidErd
  module RelationshipBuilders
    class BelongsToRelationshipBuilder < BaseRelationshipBuilder
      def build(model, assoc, models)
        from_table = model.table_name
        fk = assoc.foreign_key
        
        to_model = resolve_association_model(model, assoc)

        if to_model&.table_exists?
          # FK is on source table for belongs_to
          [Relationship.new(
            from_table, to_model.table_name, fk, "}o--||", 
            "#{from_table}.#{fk} FK → #{to_model.table_name}.#{to_model.primary_key} PK"
          )]
        else
          log_missing_table_warning(model, assoc)
        end
      end
    end
  end
end 