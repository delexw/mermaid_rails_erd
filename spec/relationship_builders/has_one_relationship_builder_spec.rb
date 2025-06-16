# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::RelationshipBuilders::HasOneRelationshipBuilder do
  let(:symbol_mapper) { double("SymbolMapper") }
  let(:association_resolver) { double("AssociationResolver") }
  let(:builder) { described_class.new(symbol_mapper: symbol_mapper, association_resolver: association_resolver) }

  describe "#build" do
    context "with standard has_one association" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      let(:models) { [] }

      before do
        allow(model).to receive(:table_name).and_return("users")
        allow(model).to receive(:primary_key).and_return("id")
        allow(assoc).to receive(:name).and_return("profile")
        allow(assoc).to receive(:foreign_key).and_return("user_id") 
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:has_one)
        
        to_table_info = { table_name: "profiles", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        allow(symbol_mapper).to receive(:map).with(:has_one).and_return("||--||")
      end

      it "creates a relationship with the correct attributes" do
        relationships = builder.build(model, assoc, models)
        expect(relationships.size).to eq(1)
        
        relationship = relationships.first
        expect(relationship.from_table).to eq("users")
        expect(relationship.to_table).to eq("profiles")
        expect(relationship.foreign_key).to eq("user_id")
        expect(relationship.relationship_type).to eq("||--||")
        expect(relationship.label).to eq("profiles.user_id FK → users.id PK")
      end
    end

    context "with polymorphic has_one association (with :as)" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      let(:models) { [] }

      before do
        allow(model).to receive(:table_name).and_return("users")
        allow(assoc).to receive(:name).and_return("avatar")
        allow(assoc).to receive(:options).and_return({ as: "imageable" })
        allow(assoc).to receive(:macro).and_return(:has_one)
        
        # Mock the symbol_mapper
        allow(symbol_mapper).to receive(:map).with(:has_one).and_return("||--||")
        
        # Mock the foreign_key method for safe_foreign_key
        allow(assoc).to receive(:foreign_key).and_return("imageable_id")
        
        # Mock for the resolve_association_model method
        # For polymorphic associations, it should return nil
        allow(builder).to receive(:resolve_association_model).with(model, assoc).and_return(nil)
        
        # Make sure builder calls the log_missing_table_warning method
        allow(builder).to receive(:log_missing_table_warning).and_return([])
      end

      it "returns an empty array for polymorphic has_one" do
        relationships = builder.build(model, assoc, models)
        expect(relationships).to eq([])
      end
    end
  end
end 