# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::RelationshipBuilders::HasAndBelongsToManyRelationshipBuilder do
  let(:symbol_mapper) { double("SymbolMapper") }
  let(:association_resolver) { double("AssociationResolver") }
  let(:printed_tables) { Set.new }
  let(:model_data_collector) { double("ModelDataCollector", register_invalid_association: nil) }
  let(:builder) { described_class.new(symbol_mapper: symbol_mapper, association_resolver: association_resolver, printed_tables: printed_tables, model_data_collector: model_data_collector) }

  describe "#build" do
    context "with standard HABTM association" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      
      before do
        # Set up the model being tested
        allow(model).to receive(:table_name).and_return("users")
        allow(model).to receive(:name).and_return("User")
        allow(model).to receive(:primary_key).and_return("id")
        
        # Set up the association properties
        allow(assoc).to receive(:name).and_return("roles")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:has_and_belongs_to_many)
        allow(assoc).to receive(:join_table).and_return("roles_users")
        allow(assoc).to receive(:foreign_key).and_return("user_id")
        allow(assoc).to receive(:association_foreign_key).and_return("role_id")
        
        # Set up the target model info via association_resolver
        to_table_info = { table_name: "roles", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        # Set up join table and check for existence
        connection = double("Connection")
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
        allow(connection).to receive(:table_exists?).with("roles_users").and_return(true)
        allow(connection).to receive(:columns).with("roles_users").and_return([])
        
        # Set up the symbol_mapper
        allow(symbol_mapper).to receive(:map).with(:has_and_belongs_to_many).and_return("}o--o{")
      end
      
      it "creates relationships for both sides of the join" do
        relationships = builder.build(model, assoc)
        
        expect(relationships.size).to eq(2)
        
        # Check user-to-join relationship
        user_join_rel = relationships[0]
        expect(user_join_rel.from_table).to eq("roles_users")
        expect(user_join_rel.to_table).to eq("users")
        expect(user_join_rel.foreign_key).to eq("user_id")
        expect(user_join_rel.relationship_type).to eq("}o--||")
        
        # Check join-to-role relationship
        join_role_rel = relationships[1]
        expect(join_role_rel.from_table).to eq("roles_users")
        expect(join_role_rel.to_table).to eq("roles")
        expect(join_role_rel.foreign_key).to eq("role_id")
        expect(join_role_rel.relationship_type).to eq("}o--||")
      end
    end
    
    context "with custom join table name" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      
      before do
        # Set up the model being tested
        allow(model).to receive(:table_name).and_return("users")
        allow(model).to receive(:name).and_return("User")
        allow(model).to receive(:primary_key).and_return("id")
        
        # Set up the association properties with custom join table
        allow(assoc).to receive(:name).and_return("projects")
        allow(assoc).to receive(:options).and_return({ join_table: "project_assignments" })
        allow(assoc).to receive(:macro).and_return(:has_and_belongs_to_many)
        allow(assoc).to receive(:join_table).and_return("project_assignments")
        allow(assoc).to receive(:foreign_key).and_return("user_id")
        allow(assoc).to receive(:association_foreign_key).and_return("project_id")
        
        # Set up the target model info via association_resolver
        to_table_info = { table_name: "projects", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        # Set up join table and check for existence
        connection = double("Connection")
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
        allow(connection).to receive(:table_exists?).with("project_assignments").and_return(true)
        allow(connection).to receive(:columns).with("project_assignments").and_return([])
        
        # Set up the symbol_mapper
        allow(symbol_mapper).to receive(:map).with(:has_and_belongs_to_many).and_return("}o--o{")
      end
      
      it "uses the custom join table name" do
        relationships = builder.build(model, assoc)
        
        expect(relationships.size).to eq(2)
        expect(relationships[0].from_table).to eq("project_assignments")
        expect(relationships[1].from_table).to eq("project_assignments")
      end
    end
    
    context "when join table does not exist" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      
      before do
        # Set up the model being tested
        allow(model).to receive(:name).and_return("User")
        allow(model).to receive(:table_name).and_return("users")
        
        # Set up the association properties
        allow(assoc).to receive(:name).and_return("roles")
        allow(assoc).to receive(:options).and_return({})
        allow(assoc).to receive(:macro).and_return(:has_and_belongs_to_many)
        allow(assoc).to receive(:join_table).and_return("roles_users")
        
        # Set up the target model info via association_resolver
        to_table_info = { table_name: "roles", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        # Set up join table check to return false
        connection = double("Connection")
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
        allow(connection).to receive(:columns).with("roles_users").and_raise(StandardError.new("Table 'roles_users' doesn't exist"))
        
        # Mock log_missing_table_warning to verify it's called
        allow(builder).to receive(:log_missing_table_warning).and_return([])
      end
      
      it "logs a warning and returns an empty array" do
        expect(builder).to receive(:log_missing_table_warning).with(model, assoc, "join table roles_users is missing: Table 'roles_users' doesn't exist")
        
        relationships = builder.build(model, assoc)
        expect(relationships).to be_empty
      end
    end
  end
end 