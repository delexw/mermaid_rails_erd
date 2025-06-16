# frozen_string_literal: true

module RailsMermaidErd
  class Relationship
    attr_reader :from_table, :to_table, :foreign_key, :relationship_type, :label
    attr_reader :fk_table, :fk_column, :pk_table, :pk_column, :is_polymorphic, :extra_label
    
    # Provide aliases for backward compatibility
    alias_method :from, :from_table
    alias_method :to, :to_table
    alias_method :symbol, :relationship_type

    def initialize(from, to, foreign_key, relationship_type, label = nil, 
                  fk_table = nil, fk_column = nil, pk_table = nil, pk_column = nil,
                  is_polymorphic = false, extra_label = nil)
      @from_table = from
      @to_table = to
      @foreign_key = foreign_key
      @relationship_type = relationship_type
      @is_polymorphic = is_polymorphic
      @extra_label = extra_label
      
      # Store FK/PK information
      @fk_table = fk_table || from
      @fk_column = fk_column || foreign_key
      @pk_table = pk_table || to
      @pk_column = pk_column || 'id'
      
      # Generate label if not provided
      @label = label || generate_label
    end

    def key
      [from_table, to_table, foreign_key].sort.join("::")
    end
    
    def generate_label
      base_label = "#{@fk_table}.#{@fk_column} FK → #{@pk_table}.#{@pk_column} PK"
      @is_polymorphic ? "#{base_label} (#{@extra_label})" : base_label
    end
  end
end