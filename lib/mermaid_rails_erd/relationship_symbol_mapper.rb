# frozen_string_literal: true

module MermaidRailsErd
  class RelationshipSymbolMapper
    def map(assoc_type)
      {
        has_many: "||--o{",
        has_one: "||--||",
        belongs_to: "}o--||",
      }[assoc_type] || "--"
    end
  end
end
