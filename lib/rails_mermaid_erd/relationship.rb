# frozen_string_literal: true

module RailsMermaidErd
  class Relationship
    attr_reader :from_table, :to_table, :foreign_key, :relationship_type, :label
    
    # Provide aliases for backward compatibility
    alias_method :from, :from_table
    alias_method :to, :to_table
    alias_method :symbol, :relationship_type

    def initialize(from, to, foreign_key, relationship_type, label)
      @from_table = from
      @to_table = to
      @foreign_key = foreign_key
      @relationship_type = relationship_type
      @label = label
    end

    def key
      [from_table, to_table, foreign_key].sort.join("::")
    end
  end
end