# frozen_string_literal: true

require_relative "base_relationship_builder"

module RailsMermaidErd
  module RelationshipBuilders
    class HasOneRelationshipBuilder < BaseRelationshipBuilder
      def build(model, assoc)
        from_table = model.table_name
        rel_type = symbol_mapper.map(assoc.macro)
        fk = safe_foreign_key(model, assoc)
        
        # Skip if we couldn't determine the foreign key
        return [] unless fk
        
        to_table_info = resolve_association_model(model, assoc)
        
        # Skip if this is a duplicate one-to-one relationship
        return [] if skip_duplicate_one_to_one?(model, assoc, to_table_info)

        if to_table_info
          [Relationship.new(
            from_table, 
            to_table_info[:table_name], 
            fk, 
            rel_type,
            nil, # Let the Relationship generate the label
            to_table_info[:table_name], # fk_table
            fk, # fk_column
            from_table, # pk_table
            model.primary_key # pk_column
          )]
        else
          log_missing_table_warning(model, assoc)
        end
      end
    end
  end
end 