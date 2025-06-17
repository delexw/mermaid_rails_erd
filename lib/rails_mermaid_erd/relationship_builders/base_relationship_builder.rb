# frozen_string_literal: true

require "set"
require_relative "../relationship"

module RailsMermaidErd
  module RelationshipBuilders
    class BaseRelationshipBuilder
      attr_reader :symbol_mapper, :association_resolver, :model_data_collector
      
      # Class variable to track one-to-one relationships across builder instances
      @@one_to_one_keys = Set.new

      def initialize(symbol_mapper:, association_resolver:, model_data_collector: nil)
        @symbol_mapper = symbol_mapper
        @association_resolver = association_resolver
        @model_data_collector = model_data_collector
      end

      def build(model, assoc)
        raise NotImplementedError, "Subclasses must implement #build"
      end
      
      protected
      
      def resolve_association_model(model, assoc)
        begin
          # Let the association_resolver handle all the resolution logic
          # including dynamic model creation when needed
          return association_resolver.resolve(assoc)
        rescue => e
          puts "  ERROR resolving association class for #{model.name}##{assoc.name}: #{e.class} - #{e.message}"
          puts e.backtrace.join("\n")
          # Register invalid association if model_data_collector is available
          register_invalid_association(model, assoc, "#{e.class} - #{e.message}")
          return nil
        end
      end
      
      def safe_foreign_key(model, assoc)
        # Skip through associations entirely
        return nil if assoc.options[:through]
        
        # Try to get the foreign key
        begin
          return assoc.foreign_key
        rescue => e
          puts "  WARNING: Cannot determine foreign key for #{model.name}##{assoc.name} - skipping"
          register_invalid_association(model, assoc, "Cannot determine foreign key: #{e.class} - #{e.message}")
          return nil
        end
      end
      
      def skip_duplicate_one_to_one?(model, assoc, to_table_info)
        return false unless [:has_one, :belongs_to].include?(assoc.macro)
        
        # Skip the check for polymorphic associations
        return false if assoc.options[:polymorphic]
        
        return false unless to_table_info
        
        # Create a unique key for this one-to-one relationship
        rel_key = [model.table_name, to_table_info[:table_name], '1:1'].sort.join("::")
        
        # Check if we've already processed this relationship
        return true if @@one_to_one_keys.include?(rel_key)
        
        # Mark this relationship as processed
        @@one_to_one_keys << rel_key
        false
      end
      
      def log_missing_table_warning(model, assoc, reason = "table does not exist")
        target_name = if assoc.options[:class_name]
                       assoc.options[:class_name].to_s.tableize
                     else
                       assoc.name.to_s.tableize
                     end
        puts "  WARNING: Could not create relationship for #{model.name}##{assoc.name} - #{reason}"
        register_invalid_association(model, assoc, reason)
        []
      end

      private

      def register_invalid_association(model, assoc, reason)
        return unless @model_data_collector
        @model_data_collector.register_invalid_association(model, assoc, reason)
      end
    end
  end
end 