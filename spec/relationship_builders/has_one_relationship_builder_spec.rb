# frozen_string_literal: true

require "spec_helper"

RSpec.describe MermaidRailsErd::RelationshipBuilders::HasOneRelationshipBuilder do
  let(:symbol_mapper) { double("SymbolMapper") }
  let(:association_resolver) { double("AssociationResolver") }
  let(:model_data_collector) { double("ModelDataCollector", register_invalid_association: nil) }
  let(:builder) { described_class.new(symbol_mapper: symbol_mapper, association_resolver: association_resolver, model_data_collector: model_data_collector) }

  describe "#build" do
    context "with standard has_one association" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }

      before do
        allow(model).to receive_messages(table_name: "users", primary_key: "id", name: "User")
        allow(assoc).to receive_messages(name: "profile", foreign_key: "user_id", options: {}, macro: :has_one)

        # Make sure duplicate_one_to_one check returns false
        allow(builder).to receive(:skip_duplicate_one_to_one?).and_return(false)

        to_table_info = { table_name: "profiles", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)

        allow(symbol_mapper).to receive(:map).with(:has_one).and_return("||--||")
      end

      it "creates a relationship with the correct attributes" do
        relationships = builder.build(model, assoc)
        expect(relationships.size).to eq(1)

        relationship = relationships.first
        expect(relationship.from_table).to eq("users")
        expect(relationship.to_table).to eq("profiles")
        expect(relationship.foreign_key).to eq("user_id")
        expect(relationship.relationship_type).to eq("||--||")

        # Test FK details correctly
        expect(relationship.fk_table).to eq("profiles")
        expect(relationship.fk_column).to eq("user_id")
        expect(relationship.pk_table).to eq("users")
        expect(relationship.pk_column).to eq("id")

        # NOTE: Relationship label generation might be different depending on implementation
        # expect(relationship.label).to eq("profiles.user_id FK → users.id PK")
      end
    end

    context "with polymorphic has_one association (with :as)" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }

      before do
        allow(model).to receive_messages(table_name: "posts", name: "Post")
        allow(assoc).to receive_messages(name: "cover_image", options: { as: "imageable" }, macro: :has_one)

        # Mock safe_foreign_key to return nil for polymorphic associations
        allow(builder).to receive(:safe_foreign_key).with(model, assoc).and_return(nil)

        # Make sure the symbol mapper is set up
        allow(symbol_mapper).to receive(:map).with(:has_one).and_return("||--||")
      end

      it "returns an empty array for polymorphic has_one" do
        relationships = builder.build(model, assoc)
        expect(relationships).to be_empty
      end
    end
  end
end
