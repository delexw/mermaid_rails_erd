# frozen_string_literal: true

require_relative "column_info"

module MermaidRailsErd
  class ModelDataCollector
    attr_reader :models_data, :tables, :models_no_tables, :models, :invalid_associations, :polymorphic_associations, :regular_associations

    def initialize(model_loader)
      @models_data = {}
      @polymorphic_associations = []
      @regular_associations = []
      @invalid_associations = []
      @polymorphic_targets = Hash.new { |h, k| h[k] = [] }
      @tables = {}
      @models_no_tables = []
      @models = model_loader.load
    end

    def collect
      (base_models & models_with_tables).each do |model|
        model_data = { model: model, associations: [] }

        # Register polymorphic interfaces that this model implements
        model.reflect_on_all_associations.each do |assoc|
          if (interface_name = assoc.options[:as])
            register_polymorphic_target(interface_name, model)
          end

          if assoc.options[:polymorphic]
            @polymorphic_associations << { model: model, association: assoc }
          else
            @regular_associations << { model: model, association: assoc }
          end

          model_data[:associations] << assoc
        end

        @models_data[model.name] = model_data

        collect_table_for_model(model)
      end

      (base_models & models_without_tables).each do |model|
        @models_no_tables << model
      end

      self
    end

    def get_model_data(model_name)
      @models_data[model_name]
    end

    # Register a model as implementing a polymorphic interface
    # @param interface_name [String, Symbol] Name of the polymorphic interface
    # @param model [Class] Model that implements the interface
    def register_polymorphic_target(interface_name, model)
      @polymorphic_targets[interface_name.to_s] << model
    end

    # Returns all models that implement the given polymorphic interface
    # @param polymorphic_name [String, Symbol] Name of the polymorphic interface
    # @return [Array<Class>] Array of models that implement the interface
    def polymorphic_targets_for(polymorphic_name)
      @polymorphic_targets[polymorphic_name.to_s] || []
    end

    # Reset all registered polymorphic targets (useful for testing)
    def reset_polymorphic_targets
      @polymorphic_targets.clear
    end

    # Collect table information from a model
    # @param model [Class] ActiveRecord model to collect table information from
    def collect_table_for_model(model)
      # Skip if we've already collected this table
      return if @tables.key?(model.table_name)

      # Collect basic table structure with columns
      @tables[model.table_name] = model.columns.map do |col|
        annotations = []
        annotations << "PK" if col.name == model.primary_key

        ColumnInfo.new(col.name, annotations, col.sql_type, col.type, col.null)
      end
    end

    # Update table definitions with foreign key annotations
    # @param relationships [Array<Relationship>] List of relationships to extract FKs from
    # @return [Hash] Updated tables hash
    def update_foreign_keys(relationships)
      fk_mapping = extract_foreign_keys(relationships)

      @tables.each do |table_name, columns|
        next unless fk_mapping[table_name]

        begin
          columns.each do |col|
            col.annotations << "FK" if fk_mapping[table_name].include?(col.name) && !col.annotations.include?("FK")
          end
        rescue StandardError => e
          puts "Error updating FK annotations for #{table_name}: #{e.message}"
        end
      end

      @tables
    end

    # Register an invalid association that couldn't be resolved
    # @param model [Class] Model containing the invalid association
    # @param assoc [ActiveRecord::Reflection::Association] Invalid association
    # @param reason [String] Reason why the association is invalid
    def register_invalid_association(model, assoc, reason = nil)
      @invalid_associations << {
        model: model,
        association: assoc,
        reason: reason,
        label: "#{model.name}##{assoc.name}",
      }
    end

    private

    def base_models
      models.reject { |model| (model < model.base_class) }
    end

    def models_with_tables
      models.select(&:table_exists?)
    end

    def models_without_tables
      models.reject(&:table_exists?)
    end

    # Extract foreign key information from relationships
    # @param relationships [Array<Relationship>] List of relationships to extract FKs from
    # @return [Hash] Mapping of table names to arrays of FK column names
    def extract_foreign_keys(relationships)
      fk_mapping = {}

      relationships.each do |rel|
        # Use the relationship attributes directly instead of parsing the label
        table_name = rel.fk_table
        fk_column = rel.fk_column

        fk_mapping[table_name] ||= []
        fk_mapping[table_name] << fk_column unless fk_mapping[table_name].include?(fk_column)
      rescue StandardError => e
        puts "Error extracting FK from relationship: #{e.message}"
      end

      fk_mapping
    end
  end
end
