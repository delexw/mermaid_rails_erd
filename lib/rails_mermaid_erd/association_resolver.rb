# frozen_string_literal: true

module RailsMermaidErd
  class AssociationResolver
    def resolve(assoc)
      # Try direct table_name access if available
      if assoc.respond_to?(:table_name)
        begin
          table_name = assoc.table_name
        rescue StandardError
          table_name = nil
        end
      end

      # Determine table name from options or plural_name if not already set
      table_name ||= if assoc.options[:table_name]
                       assoc.options[:table_name].to_s
                     else
                       assoc.plural_name.to_s
                     end

      # Check if table exists
      return nil unless ActiveRecord::Base.connection.table_exists?(table_name)

      # Return a hash with necessary information
      {
        table_name: table_name,
        primary_key: ActiveRecord::Base.connection.primary_key(table_name),
      }
    end
  end
end
