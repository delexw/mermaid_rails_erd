# frozen_string_literal: true

require_relative "base_relationship_builder"

module RailsMermaidErd
  module RelationshipBuilders
    class HasOneRelationshipBuilder < BaseRelationshipBuilder
      def build(model, assoc, models)
        from_table = model.table_name
        rel_type = symbol_mapper.map(assoc.macro)
        fk = assoc.foreign_key
        
        to_model = resolve_association_model(model, assoc)

        if to_model&.table_exists?
          [Relationship.new(
            from_table, to_model.table_name, fk, rel_type,
            "#{to_model.table_name}.#{fk} FK → #{from_table}.#{model.primary_key} PK"
          )]
        else
          log_missing_table_warning(model, assoc)
        end
      end
    end
  end
end 