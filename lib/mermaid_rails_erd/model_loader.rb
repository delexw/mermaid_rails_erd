# frozen_string_literal: true

module MermaidRailsErd
  class ModelLoader
    def load
      raise MermaidRailsErd::Error, "Rails is not loaded" unless defined?(Rails)

      Rails.application.eager_load! unless Rails.configuration.cache_classes
      ActiveRecord::Base.descendants.reject(&:abstract_class?)
    end
  end
end
