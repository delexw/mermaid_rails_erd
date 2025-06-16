# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::RelationshipSymbolMapper do
  describe "#map" do
    let(:mapper) { described_class.new }
    
    context "with different association types" do
      it "returns one-to-many symbol (||--o{) for has_many relationships" do
        symbol = mapper.map(:has_many)
        expect(symbol).to eq("||--o{")
      end
      
      it "returns one-to-one symbol (||--||) for has_one relationships" do
        symbol = mapper.map(:has_one)
        expect(symbol).to eq("||--||")
      end
      
      it "returns one-to-many symbol (}o--||) for belongs_to relationships" do
        symbol = mapper.map(:belongs_to)
        expect(symbol).to eq("}o--||")
      end
      
      it "returns default symbol (--) for unknown association types" do
        symbol = mapper.map(:unknown_type)
        expect(symbol).to eq("--")
      end
    end
  end
end 