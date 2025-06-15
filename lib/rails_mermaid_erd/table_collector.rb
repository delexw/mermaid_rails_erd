# frozen_string_literal: true

require_relative "column_info"

module RailsMermaidErd
  class TableCollector
    def collect_tables(models)
      tables = {}
      
      models.each do |model|
        next if model < model.base_class || !model.table_exists?

        # Collect basic table structure with columns as structs
        tables[model.table_name] ||= model.columns.map do |col|
          annotations = []
          annotations << "PK" if col.name == model.primary_key
          
          # Extract just the base type without precision/size information
          base_type = col.sql_type.gsub(/\(.*?\)/, '')
          
          ColumnInfo.new(base_type, col.name, annotations)
        end
      end
      
      tables
    end
    
    def update_foreign_keys(tables, relationships)
      fk_mapping = extract_foreign_keys(relationships)
      
      tables.each do |table_name, columns|
        if fk_mapping[table_name]
          begin
            columns.each do |col|
              if fk_mapping[table_name].include?(col.name)
                col.annotations << "FK" unless col.annotations.include?("FK")
              end
            end
          rescue => e
            puts "Error updating FK annotations for #{table_name}: #{e.message}"
          end
        end
      end
      
      tables
    end
    
    private
    
    def extract_foreign_keys(relationships)
      fk_mapping = {}
      
      relationships.each do |rel|
        begin
          if rel.label =~ /(.+?)\.(.+?) FK/
            table_name = $1
            fk_column = $2
            
            fk_mapping[table_name] ||= []
            fk_mapping[table_name] << fk_column unless fk_mapping[table_name].include?(fk_column)
          end
        rescue => e
          puts "Error extracting FK from relationship: #{e.message}"
        end
      end
      
      fk_mapping
    end
  end
end 