# frozen_string_literal: true

require_relative "../relationship"

module RailsMermaidErd
  module RelationshipBuilders
    class BaseRelationshipBuilder
      attr_reader :symbol_mapper, :association_resolver

      def initialize(symbol_mapper:, association_resolver:)
        @symbol_mapper = symbol_mapper
        @association_resolver = association_resolver
      end

      def build(model, assoc, models)
        raise NotImplementedError, "Subclasses must implement #build"
      end
      
      protected
      
      def resolve_association_model(model, assoc)
        begin
          to_model = association_resolver.resolve(assoc)
          
          # If we couldn't resolve the class but we have a table_name option, use that
          if to_model.nil? && assoc.options[:table_name]
            table_name = assoc.options[:table_name].to_s
            puts "  Using explicit table_name from options: #{table_name}"
            
            # Create a simple placeholder model
            to_model = Class.new(ActiveRecord::Base)
            to_model.define_singleton_method(:table_exists?) { true }
            to_model.define_singleton_method(:table_name) { table_name }
            to_model.define_singleton_method(:primary_key) { "id" }
          end
          return to_model
        rescue => e
          puts "  ERROR resolving association class for #{model.name}##{assoc.name}: #{e.class} - #{e.message}"
          puts e.backtrace.join("\n")
          return nil
        end
      end
      
      def log_missing_table_warning(model, assoc, reason = "table does not exist")
        target_name = if assoc.options[:class_name]
                       assoc.options[:class_name].to_s.tableize
                     else
                       assoc.name.to_s.tableize
                     end
        puts "  WARNING: Could not create relationship for #{model.name}##{assoc.name} - #{reason}"
        []
      end
    end
  end
end 