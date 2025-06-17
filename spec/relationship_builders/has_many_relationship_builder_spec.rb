# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::RelationshipBuilders::HasManyRelationshipBuilder do
  let(:symbol_mapper) { double("SymbolMapper") }
  let(:association_resolver) { double("AssociationResolver") }
  let(:model_data_collector) { double("ModelDataCollector", register_invalid_association: nil) }
  let(:builder) { described_class.new(symbol_mapper: symbol_mapper, association_resolver: association_resolver, model_data_collector: model_data_collector) }

  describe "#build" do
    context "with standard has_many association" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }

      before do
        allow(model).to receive(:table_name).and_return("users")
        allow(model).to receive(:primary_key).and_return("id")
        allow(assoc).to receive(:name).and_return("posts")
        allow(assoc).to receive(:foreign_key).and_return("user_id")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:has_many)
        
        to_table_info = { table_name: "posts", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        allow(symbol_mapper).to receive(:map).with(:has_many).and_return("||--o{")
      end

      it "creates a relationship with the correct attributes" do
        relationships = builder.build(model, assoc)
        expect(relationships.size).to eq(1)
        
        relationship = relationships.first
        expect(relationship.from_table).to eq("posts")
        expect(relationship.to_table).to eq("users")
        expect(relationship.foreign_key).to eq("user_id")
        expect(relationship.relationship_type).to eq("}o--||")
        expect(relationship.label).to eq("posts.user_id FK → users.id PK")
      end
    end

    context "with polymorphic has_many association (with :as)" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }

      before do
        allow(model).to receive(:table_name).and_return("posts")
        allow(assoc).to receive(:name).and_return("comments")
        allow(assoc).to receive(:options).and_return({ as: "commentable" })
        allow(assoc).to receive(:macro).and_return(:has_many)
        
        # Mock the foreign_key method for safe_foreign_key
        allow(assoc).to receive(:foreign_key).and_return(nil)
        
        # Instead of mocking resolve_association_model directly, 
        # let's make sure association_resolver responds to resolve properly
        allow(association_resolver).to receive(:resolve).and_return(nil)
        
        # Make sure builder calls the log_missing_table_warning method
        allow(builder).to receive(:log_missing_table_warning).and_return([])
      end

      it "returns an empty array for polymorphic has_many" do
        relationships = builder.build(model, assoc)
        expect(relationships).to eq([])
      end
    end
  end
end 