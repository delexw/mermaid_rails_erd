# frozen_string_literal: true

module RailsMermaidErd
  class ColumnInfo
    attr_reader :type, :name, :annotations

    def initialize(type, name, annotations = [])
      @type = type
      @name = name
      @annotations = annotations
    end
  end
end