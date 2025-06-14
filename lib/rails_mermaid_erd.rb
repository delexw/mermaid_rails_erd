# frozen_string_literal: true

require_relative "rails_mermaid_erd/version"
require_relative "rails_mermaid_erd/generator"
require_relative "rails_mermaid_erd/railtie" if defined?(Rails)

module RailsMermaidErd
  class Error < StandardError; end

  # Generate Mermaid ERD and write to output stream
  # @param output [IO] Output stream to write the ERD to
  def self.generate(output: $stdout)
    Generator.new(output: output).generate
  end
end 