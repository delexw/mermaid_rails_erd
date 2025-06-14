# frozen_string_literal: true

module RailsMermaidErd
  class ModelLoader
    def load
      Rails.application.eager_load! unless Rails.configuration.cache_classes
      ActiveRecord::Base.descendants.reject(&:abstract_class?)
    end
  end
end 