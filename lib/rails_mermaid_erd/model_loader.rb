# frozen_string_literal: true

module RailsMermaidErd
  class ModelLoader
    def load
      unless defined?(Rails)
        raise RailsMermaidErd::Error, "Rails is not loaded"
      end
      
      Rails.application.eager_load! unless Rails.configuration.cache_classes
      ActiveRecord::Base.descendants.reject(&:abstract_class?)
    end
  end
end 