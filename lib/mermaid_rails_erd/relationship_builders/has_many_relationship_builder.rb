# frozen_string_literal: true

require_relative "base_relationship_builder"

module MermaidRailsErd
  module RelationshipBuilders
    class HasManyRelationshipBuilder < BaseRelationshipBuilder
      def build(model, assoc)
        from_table = model.table_name
        fk = safe_foreign_key(model, assoc)

        # Skip if we couldn't determine the foreign key
        return [] unless fk

        to_table_info = resolve_association_model(model, assoc)

        if to_table_info
          # FK is on target table for has_many
          [Relationship.new(
            to_table_info[:table_name],
            from_table,
            fk,
            "}o--||",
            nil, # Let the Relationship generate the label
            to_table_info[:table_name], # fk_table
            fk, # fk_column
            from_table, # pk_table
            model.primary_key, # pk_column
          )]
        else
          log_missing_table_warning(model, assoc)
        end
      end
    end
  end
end
