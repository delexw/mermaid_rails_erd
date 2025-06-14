# frozen_string_literal: true

require_relative "relationship"
require_relative "mermaid_emitter"
require_relative 'column_info'

module RailsMermaidErd
  class Generator
    def initialize(output:)
      @output = output
      @printed_tables = Set.new
      @printed_relationships = Set.new
      @one_to_one_keys = Set.new
      @foreign_keys = {}

      if ActiveRecord::Base.connection.respond_to?(:foreign_keys)
        ActiveRecord::Base.connection.tables.each do |table|
          begin
            @foreign_keys[table] = ActiveRecord::Base.connection.foreign_keys(table).map(&:column)
          rescue
            @foreign_keys[table] = []
          end
        end
      end
    end

    def generate
      models = load_models
      tables = {}
      relationships = []

      # First pass: collect tables and build relationships
      models.each do |model|
        begin
          puts "Processing model: #{model.name}"
          next if model < model.base_class || !model.table_exists?

          # Collect basic table structure with columns as structs
          tables[model.table_name] ||= model.columns.map do |col|
            annotations = []
            annotations << "PK" if col.name == model.primary_key
            ColumnInfo.new(col.sql_type, col.name, annotations)
          end

          model.reflect_on_all_associations.each do |assoc|
            begin
              puts "  Checking association: #{model.name}##{assoc.name} (#{assoc.macro}) - Polymorphic: #{assoc.options[:polymorphic] || false}"
              next if skip_duplicate_one_to_one?(model, assoc)
              relationships += build_relationships_for(model, assoc, models)
            rescue => e
              puts "ERROR processing association #{model.name}##{assoc.name}: #{e.class} - #{e.message}"
              puts e.backtrace.join("\n")
            end
          end
        rescue => e
          puts "ERROR processing model #{model.name}: #{e.class} - #{e.message}"
          puts e.backtrace.join("\n")
        end
      end

      puts "Finished processing models. Found #{relationships.size} relationships."
      
      # Second pass: extract FK info from relationships
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

      # Third pass: update table definitions with FK annotations
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

      MermaidEmitter.new(@output, tables, relationships).emit
    end

    private

    def load_models
      Rails.application.eager_load! unless Rails.configuration.cache_classes
      ActiveRecord::Base.descendants.reject(&:abstract_class?)
    end

    def relationship_symbol(assoc)
      {
        has_many: "||--o{",
        has_one: "||--||",
        belongs_to: "}o--||"
      }[assoc.macro] || "--"
    end

    def foreign_key_column?(model, column_name)
      table = model.table_name
      if @foreign_keys[table]
        @foreign_keys[table].include?(column_name)
      else
        model.reflect_on_all_associations(:belongs_to).any? do |assoc|
          assoc.foreign_key.to_s == column_name.to_s
        end
      end
    end

    def skip_duplicate_one_to_one?(model, assoc)
      return false unless [:has_one, :belongs_to].include?(assoc.macro)
      to_model = resolve_association_class(assoc)
      return true unless to_model&.table_exists?
      rel_key = [model.table_name, to_model.table_name, '1:1'].sort.join("::")
      return true if @one_to_one_keys.include?(rel_key)
      @one_to_one_keys << rel_key
      false
    end

    def build_relationships_for(model, assoc, models)
      from_table = model.table_name
      rel_type = relationship_symbol(assoc)
      fk = assoc.foreign_key
      
      puts "Processing association: #{model.name}##{assoc.name} (#{assoc.macro})"
      
      # Check for polymorphic association FIRST
      if assoc.options[:polymorphic]
        puts "  Found polymorphic association for #{model.name}##{assoc.name}"
        return resolve_polymorphic_targets(assoc.name.to_s, from_table, rel_type, models)
      end
      
      # Only try to resolve the class for non-polymorphic associations
      begin
        puts "  Attempting to resolve class for non-polymorphic association: #{model.name}##{assoc.name}"
        to_model = resolve_association_class(assoc)
        puts "  Resolved association class: #{to_model&.name || 'nil'}"
      rescue => e
        puts "  ERROR resolving association class for #{model.name}##{assoc.name}: #{e.class} - #{e.message}"
        puts e.backtrace.join("\n")
        return []
      end

      if assoc.macro == :has_and_belongs_to_many
        puts "  Processing HABTM relationship between #{from_table} and #{to_model&.table_name || 'unknown'}"
        return build_habtm_relationships(from_table, to_model, assoc)
      elsif to_model&.table_exists?
        puts "  Creating standard relationship from #{from_table} to #{to_model.table_name}"
        
        if [:has_many, :belongs_to].include?(assoc.macro)
          # Use consistent o{ -- || direction for both has_many and belongs_to
          # Swap the tables to point in the right direction but keep FK info correct
          if assoc.macro == :has_many
            # FK is on target table for has_many
            return [Relationship.new(
              to_model.table_name, from_table, fk, "}o--||",
              "#{to_model.table_name}.#{fk} FK → #{from_table}.#{model.primary_key} PK"
            )]
          else # belongs_to
            # FK is on source table for belongs_to
            return [Relationship.new(
              from_table, to_model.table_name, fk, "}o--||", 
              "#{from_table}.#{fk} FK → #{to_model.table_name}.#{to_model.primary_key} PK"
            )]
          end
        else # has_one
          return [Relationship.new(
            from_table, to_model.table_name, fk, rel_type,
            "#{to_model.table_name}.#{fk} FK → #{from_table}.#{model.primary_key} PK"
          )]
        end
      else
        puts "  Creating fallback relationship for #{assoc.name}"
        return [Relationship.new(
          from_table, assoc.name.to_s, fk, rel_type,
          "#{from_table}.#{fk} → #{assoc.name} (?)"
        )]
      end
    end

    def build_habtm_relationships(from_table, to_model, assoc)
      join_table = assoc.join_table.to_s
      puts "  HABTM join table: #{join_table}"
      
      # Check if we need to verify the table existence
      unless @printed_tables.include?(join_table)
        begin
          puts "  Checking if join table exists: #{join_table}"
          ActiveRecord::Base.connection.columns(join_table)
          @printed_tables << join_table
          puts "  Join table exists and has been added to printed tables"
        rescue => e
          puts "  Error: Join table #{join_table} for #{from_table} and #{to_model.table_name} is missing: #{e.message}"
          return [] # Return empty array if join table doesn't exist
        end
      else
        puts "  Join table already processed: #{join_table}"
      end
      
      # If we reach here, the join table exists, so create relationships
      puts "  Creating HABTM relationships for #{join_table}"
      [
        Relationship.new(
          join_table, from_table, assoc.foreign_key, "}o--||",
          "#{join_table}.#{assoc.foreign_key} FK → #{from_table}.id PK"),
        Relationship.new(
          join_table, to_model.table_name, assoc.association_foreign_key, "}o--||",
          "#{join_table}.#{assoc.association_foreign_key} FK → #{to_model.table_name}.id PK")
      ]
    end

    def resolve_polymorphic_targets(name, from_table, rel_type, models)
      puts "  Looking for models with #{name}_id column for polymorphic association"
      target_models = models.select { |m| m.table_exists? && m.column_names.include?("#{name}_id") }
      puts "  Found #{target_models.size} potential target models for polymorphic association"
      
      target_models.map do |target|
        puts "  Creating polymorphic relationship from #{from_table} to #{target.table_name}"
        Relationship.new(
          from_table, target.table_name, "#{name}_id", rel_type,
          "#{from_table}.#{name}_id FK → #{target.table_name}.id PK (polymorphic)"
        )
      end
    end

    def resolve_association_class(assoc)
      begin
        klass = assoc.klass
        puts "  Resolved association class directly: #{klass.name}"
        return klass
      rescue NameError => e
        puts "  Could not resolve class directly: #{e.message}"
        class_name = assoc.options[:class_name]&.safe_constantize
        if class_name
          puts "  Resolved class from :class_name option: #{class_name}"
          return class_name
        end
        
        classified = assoc.name.to_s.classify.safe_constantize
        if classified
          puts "  Resolved class by classification: #{classified}"
          return classified
        end
        
        puts "  Could not resolve association class by any method"
        return nil
      end
    end
  end
end 