# frozen_string_literal: true

module RailsMermaidErd
  class AssociationResolver
    def resolve(assoc)
      begin
        klass = assoc.klass
        return klass
      rescue NameError, ArgumentError => e
        # Try multiple approaches to resolve the class
        # 1. Try using class_name option
        if assoc.options[:class_name]
          class_name = assoc.options[:class_name].to_s
          resolved = class_name.safe_constantize
          return resolved if resolved
        end
        
        # 2. Try standard classify approach
        standard_class_name = assoc.name.to_s.classify
        resolved = standard_class_name.safe_constantize
        return resolved if resolved
        
        # 3. Try within the namespace of the source model
        if assoc.active_record.name.include?('::')
          namespace = assoc.active_record.name.deconstantize
          namespaced_class = "#{namespace}::#{standard_class_name}".safe_constantize
          return namespaced_class if namespaced_class
        end
        
        # Generate best guess for table name
        table_name = if assoc.options[:table_name]
          assoc.options[:table_name].to_s
        else
          assoc.name.to_s.tableize
        end
        
        # Check if table exists
        if ActiveRecord::Base.connection.table_exists?(table_name)
          # Create dynamic model class for diagram purposes
          klass = Class.new(ActiveRecord::Base)
          klass.define_singleton_method(:table_exists?) { true }
          klass.define_singleton_method(:table_name) { table_name }
          klass.define_singleton_method(:primary_key) { "id" }
          return klass
        end
        
        puts "  Failed all attempts to resolve association class for #{assoc.name}"
        return nil
      end
    end
  end
end 