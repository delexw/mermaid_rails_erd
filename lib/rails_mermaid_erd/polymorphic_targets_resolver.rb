# frozen_string_literal: true

require_relative "relationship"

module RailsMermaidErd
  class PolymorphicTargetsResolver
    def resolve(name, from_table, rel_type, models)
      target_models = models.select { |m| m.table_exists? && m.column_names.include?("#{name}_id") }
      
      target_models.map do |target|
        Relationship.new(
          from_table, target.table_name, "#{name}_id", rel_type,
          "#{from_table}.#{name}_id FK → #{target.table_name}.id PK (polymorphic)"
        )
      end
    end
  end
end 