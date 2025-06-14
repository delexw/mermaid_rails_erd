# frozen_string_literal: true

require_relative "relationship_builders/belongs_to_relationship_builder"
require_relative "relationship_builders/has_many_relationship_builder"
require_relative "relationship_builders/has_one_relationship_builder"
require_relative "relationship_builders/habtm_relationship_builder"

module RailsMermaidErd
  class RelationshipRegistry
    attr_reader :builders, :polymorphic_resolver

    def initialize(symbol_mapper:, association_resolver:, polymorphic_resolver:, printed_tables: Set.new)
      @polymorphic_resolver = polymorphic_resolver
      @one_to_one_keys = Set.new
      
      @builders = {
        belongs_to: RelationshipBuilders::BelongsToRelationshipBuilder.new(
          symbol_mapper: symbol_mapper, 
          association_resolver: association_resolver
        ),
        has_many: RelationshipBuilders::HasManyRelationshipBuilder.new(
          symbol_mapper: symbol_mapper, 
          association_resolver: association_resolver
        ),
        has_one: RelationshipBuilders::HasOneRelationshipBuilder.new(
          symbol_mapper: symbol_mapper, 
          association_resolver: association_resolver
        ),
        has_and_belongs_to_many: RelationshipBuilders::HasAndBelongsToManyRelationshipBuilder.new(
          symbol_mapper: symbol_mapper, 
          association_resolver: association_resolver,
          printed_tables: printed_tables
        )
      }
    end

    def build_relationships(model, assoc, models)
      # Check for polymorphic association first
      if assoc.options[:polymorphic]
        from_table = model.table_name
        rel_type = builders[assoc.macro].symbol_mapper.map(assoc.macro)
        return polymorphic_resolver.resolve(assoc.name.to_s, from_table, rel_type, models)
      end
      
      # Skip duplicate one-to-one relationships
      return [] if skip_duplicate_one_to_one?(model, assoc)
      
      # Delegate to the appropriate builder
      builder = builders[assoc.macro]
      return builder.build(model, assoc, models) if builder
      
      # If no builder exists for this macro type, return an empty array
      []
    end
    
    private
    
    def skip_duplicate_one_to_one?(model, assoc)
      return false unless [:has_one, :belongs_to].include?(assoc.macro)
      
      # Skip the check for polymorphic associations
      return false if assoc.options[:polymorphic]
      
      begin
        association_resolver = builders[assoc.macro].association_resolver
        to_model = association_resolver.resolve(assoc)
        return true unless to_model&.table_exists?
        rel_key = [model.table_name, to_model.table_name, '1:1'].sort.join("::")
        return true if @one_to_one_keys.include?(rel_key)
        @one_to_one_keys << rel_key
        false
      rescue => e
        puts "  Error in skip_duplicate_one_to_one? for #{model.name}##{assoc.name}: #{e.message}"
        false # Don't skip if we encounter an error
      end
    end
  end
end 