# frozen_string_literal: true

require_relative "relationship"

module MermaidRailsErd
  class PolymorphicTargetsResolver
    attr_reader :model_data_collector

    def initialize(model_data_collector)
      @model_data_collector = model_data_collector
    end

    def resolve(name, from_table, rel_type)
      # Get all models that implement the polymorphic interface
      target_models = model_data_collector.polymorphic_targets_for(name)

      # Create relationships for each target model
      target_models.map do |target|
        fk_column = "#{name}_id"
        Relationship.new(
          from_table,
          target.table_name,
          fk_column,
          rel_type,
          nil, # Let the Relationship generate the label
          from_table, # fk_table
          fk_column, # fk_column
          target.table_name, # pk_table
          "id", # pk_column
          # Add (polymorphic) to the label
          true, # is_polymorphic
          "polymorphic", # extra_label
        )
      end
    end
  end
end
