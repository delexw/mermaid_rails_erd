# frozen_string_literal: true

require_relative "relationship"

module RailsMermaidErd
  class PolymorphicTargetsResolver
    attr_reader :model_data_collector
    
    def initialize(model_data_collector)
      @model_data_collector = model_data_collector
    end
    
    def resolve(name, from_table, rel_type, models)
      # Get all models that implement the polymorphic interface
      target_models = model_data_collector.polymorphic_targets_for(name)
      
      # Create relationships for each target model
      target_models.map do |target|
        Relationship.new(
          from_table, target.table_name, "#{name}_id", rel_type,
          "#{from_table}.#{name}_id FK → #{target.table_name}.id PK (polymorphic)"
        )
      end
    end
  end
end 