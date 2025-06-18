# frozen_string_literal: true

module RailsMermaidErd
  class MermaidEmitter
    def initialize(output, tables, relationships)
      @output = output
      @tables = tables
      @relationships = relationships
    end

    def emit
      @output.puts "erDiagram"

      @tables.each do |table_name, columns|
        @output.puts "    #{table_name} {"
        columns.each do |col|
          annotations = col.annotations.empty? ? "" : " #{col.annotations.join(' ')}"
          @output.puts "        #{col.activerecord_type} #{col.name}#{annotations}"
        end
        @output.puts "    }"
      end

      @output.puts

      emitted = Set.new
      @relationships.each do |rel|
        next if emitted.include?(rel.key)

        emitted << rel.key
        @output.puts "    #{rel.from_table} #{rel.relationship_type} #{rel.to_table} : \"#{rel.label}\""
      end
    end
  end
end
