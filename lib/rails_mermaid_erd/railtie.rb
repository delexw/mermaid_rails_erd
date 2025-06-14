# frozen_string_literal: true

module RailsMermaidErd
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../../tasks/rails_mermaid_erd.rake', __FILE__)
    end
  end
end 