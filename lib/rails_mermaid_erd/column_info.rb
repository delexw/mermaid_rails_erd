# frozen_string_literal: true

module RailsMermaidErd
  class ColumnInfo
    attr_reader :type, :name, :annotations, :raw_sql_type, :activerecord_type

    def initialize(type, name, annotations = [], raw_sql_type = nil, activerecord_type = nil)
      @type = type
      @name = name
      @annotations = annotations
      @raw_sql_type = raw_sql_type
      @activerecord_type = activerecord_type
    end
  end
end