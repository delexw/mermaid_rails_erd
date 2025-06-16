# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::RelationshipBuilders::BelongsToRelationshipBuilder do
  let(:symbol_mapper) { double("SymbolMapper") }
  let(:association_resolver) { double("AssociationResolver") }
  let(:builder) { described_class.new(symbol_mapper: symbol_mapper, association_resolver: association_resolver) }

  describe "#build" do
    context "with standard belongs_to association" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      let(:models) { [] }

      before do
        allow(model).to receive(:table_name).and_return("models")
        allow(assoc).to receive(:name).and_return("parent")
        allow(assoc).to receive(:foreign_key).and_return("parent_id")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:belongs_to)
        
        to_table_info = { table_name: "parents", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
      end

      it "creates a relationship with the correct attributes" do
        relationships = builder.build(model, assoc, models)
        expect(relationships.size).to eq(1)
        
        relationship = relationships.first
        expect(relationship.from_table).to eq("models")
        expect(relationship.to_table).to eq("parents")
        expect(relationship.foreign_key).to eq("parent_id")
        expect(relationship.relationship_type).to eq("}o--||")
        expect(relationship.label).to eq("models.parent_id FK → parents.id PK")
      end
    end

    context "when foreign key cannot be determined" do
      let(:model) { double("Model", name: "Model") }
      let(:assoc) { double("Association", name: "parent", options: {}) }
      let(:models) { [] }

      before do
        allow(model).to receive(:table_name).and_return("models")
        
        # Use a custom error class instead of NoMethodError to avoid Module::DelegationError
        class TestError < StandardError; end
        allow(assoc).to receive(:foreign_key).and_raise(TestError)
        
        # Mock the safe_foreign_key method to return nil
        allow_any_instance_of(RailsMermaidErd::RelationshipBuilders::BaseRelationshipBuilder)
          .to receive(:safe_foreign_key)
          .with(model, assoc)
          .and_return(nil)
      end

      it "returns an empty array" do
        relationships = builder.build(model, assoc, models)
        expect(relationships).to eq([])
      end
    end

    context "when target model cannot be resolved" do
      let(:model) { double("Model", name: "Model") }
      let(:assoc) { double("Association", name: "parent") }
      let(:models) { [] }

      before do
        allow(model).to receive(:table_name).and_return("models")
        allow(assoc).to receive(:foreign_key).and_return("parent_id")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:belongs_to)
        
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(nil)
        allow(builder).to receive(:log_missing_table_warning).with(model, assoc).and_return([])
      end

      it "logs a warning and returns an empty array" do
        expect(builder).to receive(:log_missing_table_warning).with(model, assoc)
        relationships = builder.build(model, assoc, models)
        expect(relationships).to eq([])
      end
    end

    context "with duplicate one-to-one relationship" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      let(:models) { [] }

      before do
        allow(model).to receive(:table_name).and_return("models")
        allow(assoc).to receive(:name).and_return("parent")
        allow(assoc).to receive(:foreign_key).and_return("parent_id")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:belongs_to)
        
        to_table_info = { table_name: "parents", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        # Make it appear as a duplicate
        allow(builder).to receive(:skip_duplicate_one_to_one?).and_return(true)
      end

      it "returns an empty array" do
        relationships = builder.build(model, assoc, models)
        expect(relationships).to eq([])
      end
    end
  end
end 