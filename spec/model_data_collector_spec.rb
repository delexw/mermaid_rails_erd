# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::ModelDataCollector do
  let(:collector) { described_class.new }

  before do
    collector.reset_polymorphic_targets
  end

  describe "#collect" do
    it "registers models implementing polymorphic interfaces" do
      # Create mock models
      post_model = double("PostModel")
      association = double("Association", options: { as: :commentable })
      allow(post_model).to receive(:reflect_on_all_associations).and_return([association])
      allow(post_model).to receive(:name).and_return("PostModel")
      allow(post_model).to receive(:base_class).and_return(Object)
      allow(post_model).to receive(:<).and_return(false)
      allow(post_model).to receive(:table_exists?).and_return(false)
      
      # Collect the model data
      collector.collect([post_model])
      
      # Check that the model was registered as a target for the commentable interface
      targets = collector.polymorphic_targets_for("commentable")
      expect(targets).to include(post_model)
    end
    
    it "separates polymorphic and regular associations" do
      # Create mock model with both types of associations
      model = double("Model")
      poly_assoc = double("PolyAssoc", options: { polymorphic: true })
      regular_assoc = double("RegularAssoc", options: {})
      
      allow(model).to receive(:reflect_on_all_associations).and_return([poly_assoc, regular_assoc])
      allow(model).to receive(:name).and_return("Model")
      allow(model).to receive(:base_class).and_return(Object)
      allow(model).to receive(:<).and_return(false)
      allow(model).to receive(:table_exists?).and_return(false)
      
      # Collect the model data
      collector.collect([model])
      
      # Verify associations were categorized correctly
      expect(collector.polymorphic_associations.length).to eq(1)
      expect(collector.polymorphic_associations.first[:association]).to eq(poly_assoc)
      
      expect(collector.regular_associations.length).to eq(1)
      expect(collector.regular_associations.first[:association]).to eq(regular_assoc)
    end

    it "collects table information for models with tables" do
      model = double("TableModel")
      
      # Column mocks
      id_column = double("IdColumn", name: "id", sql_type: "integer")
      name_column = double("NameColumn", name: "name", sql_type: "varchar(255)")
      
      # Model setup
      allow(model).to receive(:reflect_on_all_associations).and_return([])
      allow(model).to receive(:name).and_return("TableModel")
      allow(model).to receive(:base_class).and_return(Object)
      allow(model).to receive(:<).and_return(false)
      allow(model).to receive(:table_exists?).and_return(true)
      allow(model).to receive(:table_name).and_return("table_models")
      allow(model).to receive(:columns).and_return([id_column, name_column])
      allow(model).to receive(:primary_key).and_return("id")
      
      # Collect the model data
      collector.collect([model])
      
      # Verify table was collected
      expect(collector.tables).to have_key("table_models")
      expect(collector.tables["table_models"].length).to eq(2)
      
      # Check column details
      id_col_info = collector.tables["table_models"].find { |col| col.name == "id" }
      expect(id_col_info).not_to be_nil
      expect(id_col_info.annotations).to include("PK")
      
      name_col_info = collector.tables["table_models"].find { |col| col.name == "name" }
      expect(name_col_info).not_to be_nil
      expect(name_col_info.type).to eq("varchar")
    end
  end
  
  describe "#update_foreign_keys" do
    it "adds FK annotations to foreign key columns" do
      # Set up a table with columns
      model = double("Model")
      id_column = double("IdColumn", name: "id", sql_type: "integer")
      fk_column = double("FkColumn", name: "user_id", sql_type: "integer")
      
      # Table collection setup
      allow(model).to receive(:reflect_on_all_associations).and_return([])
      allow(model).to receive(:name).and_return("Model")
      allow(model).to receive(:base_class).and_return(Object)
      allow(model).to receive(:<).and_return(false)
      allow(model).to receive(:table_exists?).and_return(true)
      allow(model).to receive(:table_name).and_return("models")
      allow(model).to receive(:columns).and_return([id_column, fk_column])
      allow(model).to receive(:primary_key).and_return("id")
      
      # First collect the table
      collector.collect([model])
      
      # Create a mock relationship with FK information
      relationship = double("Relationship", 
                         label: "models.user_id FK → users.id PK", 
                         from_table: "models", 
                         to_table: "users", 
                         foreign_key: "user_id")
      
      # Update foreign keys
      collector.update_foreign_keys([relationship])
      
      # Check FK annotation was added
      fk_col_info = collector.tables["models"].find { |col| col.name == "user_id" }
      expect(fk_col_info).not_to be_nil
      expect(fk_col_info.annotations).to include("FK")
    end
  end
  
  describe "#register_polymorphic_target" do
    it "adds models to the appropriate polymorphic interface" do
      model1 = double("Model1")
      model2 = double("Model2")
      
      collector.register_polymorphic_target("likeable", model1)
      collector.register_polymorphic_target("likeable", model2)
      
      targets = collector.polymorphic_targets_for("likeable")
      expect(targets).to match_array([model1, model2])
    end
  end
  
  describe "#polymorphic_targets_for" do
    it "returns empty array for unknown interfaces" do
      expect(collector.polymorphic_targets_for("unknown")).to eq([])
    end
    
    it "returns registered models for known interfaces" do
      model = double("Model")
      collector.register_polymorphic_target("shareable", model)
      
      expect(collector.polymorphic_targets_for("shareable")).to eq([model])
    end
  end
  
  describe "#reset_polymorphic_targets" do
    it "clears all registered polymorphic targets" do
      collector.register_polymorphic_target("testable", double("TestModel"))
      expect(collector.polymorphic_targets_for("testable")).not_to be_empty
      
      collector.reset_polymorphic_targets
      expect(collector.polymorphic_targets_for("testable")).to be_empty
    end
  end
end 