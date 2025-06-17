# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::RelationshipBuilders::BelongsToRelationshipBuilder do
  let(:symbol_mapper) { double("SymbolMapper") }
  let(:association_resolver) { double("AssociationResolver") }
  let(:model_data_collector) { double("ModelDataCollector", register_invalid_association: nil) }
  let(:builder) { described_class.new(symbol_mapper: symbol_mapper, association_resolver: association_resolver, model_data_collector: model_data_collector) }

  describe "#build" do
    context "with standard belongs_to association" do
      let(:model) { double("Model", table_name: "comments") }
      let(:assoc) { double("Association") }
      
      before do
        allow(assoc).to receive(:name).and_return("post")
        allow(assoc).to receive(:foreign_key).and_return("post_id")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:belongs_to)
        
        # Set up the association_resolver to return info about the target model
        to_table_info = { table_name: "posts", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        # Set up the symbol_mapper to return the appropriate relationship type
        allow(symbol_mapper).to receive(:map).with(:belongs_to).and_return("}o--||")
      end
      
      it "creates a relationship with the correct attributes" do
        relationships = builder.build(model, assoc)
        
        expect(relationships.size).to eq(1)
        relationship = relationships.first
        
        expect(relationship.from_table).to eq("comments")
        expect(relationship.to_table).to eq("posts")
        expect(relationship.foreign_key).to eq("post_id")
        expect(relationship.relationship_type).to eq("}o--||")
        
        # Check FK details
        expect(relationship.fk_column).to eq("post_id")
        expect(relationship.fk_table).to eq("comments")
      end
    end
    
    context "when foreign key cannot be determined" do
      let(:model) { double("Model", table_name: "comments") }
      let(:assoc) { double("Association") }
      
      before do
        allow(assoc).to receive(:name).and_return("post")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:belongs_to)
        
        # Mock safe_foreign_key to return nil
        allow(builder).to receive(:safe_foreign_key).and_return(nil)
      end
      
      it "returns an empty array" do
        relationships = builder.build(model, assoc)
        expect(relationships).to be_empty
      end
    end
    
    context "when target model cannot be resolved" do
      let(:model) { double("Model", name: "Comment", table_name: "comments") }
      let(:assoc) { double("Association") }
      
      before do
        allow(assoc).to receive(:name).and_return("post")
        allow(assoc).to receive(:foreign_key).and_return("post_id")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:belongs_to)
        
        # Association resolver returns nil for unresolvable target
        allow(association_resolver).to receive(:resolve).and_return(nil)
        
        # Mock log_missing_table_warning to verify it's called
        allow(builder).to receive(:log_missing_table_warning).and_return([])
      end
      
      it "logs a warning and returns an empty array" do
        expect(builder).to receive(:log_missing_table_warning).with(model, assoc)
        
        relationships = builder.build(model, assoc)
        expect(relationships).to be_empty
      end
      
      it "registers the invalid association with the model_data_collector" do
        expect(model_data_collector).to receive(:register_invalid_association).with(model, assoc, any_args)
        
        # Allow log_missing_table_warning to call through to the original method
        allow(builder).to receive(:log_missing_table_warning).and_call_original
        
        relationships = builder.build(model, assoc)
        expect(relationships).to be_empty
      end
    end
    
    context "with duplicate one-to-one relationship" do
      let(:model) { double("Model", table_name: "users") }
      let(:assoc) { double("Association") }
      let(:other_model) { double("OtherModel", table_name: "profiles") }
      let(:other_assoc) { double("OtherAssociation") }
      
      before do
        # Set up first relationship (User belongs_to Profile)
        allow(assoc).to receive(:name).and_return("profile")
        allow(assoc).to receive(:foreign_key).and_return("profile_id")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:belongs_to)
        
        to_table_info = { table_name: "profiles", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        # Set up second relationship (Profile belongs_to User)
        allow(other_assoc).to receive(:name).and_return("user")
        allow(other_assoc).to receive(:foreign_key).and_return("user_id")
        allow(other_assoc).to receive(:options).and_return({})
        allow(other_assoc).to receive(:macro).and_return(:belongs_to)
        
        other_to_table_info = { table_name: "users", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(other_assoc).and_return(other_to_table_info)
        
        # Set up the symbol_mapper
        allow(symbol_mapper).to receive(:map).with(:belongs_to).and_return("}o--||")
        
        # Process the first relationship to set up duplicate detection
        allow(builder).to receive(:skip_duplicate_one_to_one?).and_call_original
        builder.build(model, assoc)
        
        # Now for the second relationship, fake the duplicate check
        allow(builder).to receive(:skip_duplicate_one_to_one?).with(other_model, other_assoc, other_to_table_info).and_return(true)
      end
      
      it "returns an empty array" do
        relationships = builder.build(other_model, other_assoc)
        expect(relationships).to be_empty
      end
    end
  end
end 