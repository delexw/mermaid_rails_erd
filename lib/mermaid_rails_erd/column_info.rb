# frozen_string_literal: true

module MermaidRailsErd
  class ColumnInfo
    attr_reader :name, :annotations, :raw_sql_type, :activerecord_type, :isNullable

    def initialize(name, annotations = [], raw_sql_type = nil, activerecord_type = nil, isNullable = nil)
      @name = name
      @annotations = annotations
      @raw_sql_type = raw_sql_type
      @activerecord_type = activerecord_type
      @isNullable = isNullable
    end
  end
end
