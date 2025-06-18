# frozen_string_literal: true

require_relative "base_relationship_builder"

module MermaidRailsErd
  module RelationshipBuilders
    class BelongsToRelationshipBuilder < BaseRelationshipBuilder
      def build(model, assoc)
        from_table = model.table_name
        fk = safe_foreign_key(model, assoc)

        # Skip if we couldn't determine the foreign key
        return [] unless fk

        to_table_info = resolve_association_model(model, assoc)

        # Skip if this is a duplicate one-to-one relationship
        return [] if skip_duplicate_one_to_one?(model, assoc, to_table_info)

        if to_table_info
          # FK is on source table for belongs_to
          [Relationship.new(
            from_table,
            to_table_info[:table_name],
            fk,
            "}o--||",
            nil, # Let the Relationship generate the label
            from_table, # fk_table
            fk, # fk_column
            to_table_info[:table_name], # pk_table
            to_table_info[:primary_key], # pk_column
          )]
        else
          log_missing_table_warning(model, assoc)
        end
      end
    end
  end
end
