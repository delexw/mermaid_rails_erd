# frozen_string_literal: true

module RailsMermaidErd
  # Class to hold parsed ERD data with delegation to model_data_collector
  # Provides structured access to relationships, tables, and model data
  class ParsedData
    attr_reader :relationships, :tables, :model_data_collector
    
    # Initialize with collected ERD data
    # @param relationships [Array] Array of relationship objects
    # @param tables [Hash] Hash of table definitions keyed by table name
    # @param model_data_collector [ModelDataCollector] Collector instance with model data
    def initialize(relationships, tables, model_data_collector)
      @relationships = relationships
      @tables = tables
      @model_data_collector = model_data_collector
    end
    
    # Delegated methods from model_data_collector for better IDE support
    
    # @return [Hash] Hash of model data keyed by model name
    def models_data
      model_data_collector.models_data
    end
    
    # @return [Hash] Hash of models without tables keyed by model name  
    def models_no_tables
      model_data_collector.models_no_tables
    end
    
    # @return [Array] Array of all loaded models
    def models
      model_data_collector.models
    end
    
    # @return [Array<Hash>] Array of invalid associations with details
    def invalid_associations
      model_data_collector.invalid_associations
    end
    
    # @return [Array<Hash>] Array of polymorphic associations
    def polymorphic_associations
      model_data_collector.polymorphic_associations
    end
    
    # @return [Array<Hash>] Array of regular (non-polymorphic) associations
    def regular_associations
      model_data_collector.regular_associations
    end
  end
end 