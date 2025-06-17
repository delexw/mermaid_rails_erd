# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::ModelDataCollector do
  let(:model_loader) { double("ModelLoader") }
  let(:collector) { described_class.new(model_loader) }

  before do
    # Set up test models
    post_model = double("PostModel")
    association = double("Association", options: { as: :commentable })
    allow(post_model).to receive_messages(reflect_on_all_associations: [association], name: "PostModel", base_class: Object, "<": false, table_exists?: true, table_name: "posts", columns: [], primary_key: "id")

    model = double("Model")
    poly_assoc = double("PolyAssoc", options: { polymorphic: true })
    regular_assoc = double("RegularAssoc", options: {})
    allow(model).to receive_messages(reflect_on_all_associations: [poly_assoc, regular_assoc], name: "Model", base_class: Object, "<": false, table_exists?: true, table_name: "models", columns: [], primary_key: "id")

    table_model = double("TableModel")
    id_column = double("IdColumn", name: "id", sql_type: "integer", type: :integer, null: false)
    name_column = double("NameColumn", name: "name", sql_type: "varchar(255)", type: :string, null: true)
    allow(table_model).to receive_messages(reflect_on_all_associations: [], name: "TableModel", base_class: Object, "<": false, table_exists?: true, table_name: "table_models", columns: [id_column, name_column], primary_key: "id")

    # Initialize with models
    allow(model_loader).to receive(:load).and_return([post_model, model, table_model])

    collector.reset_polymorphic_targets
  end

  describe "#collect" do
    it "registers models implementing polymorphic interfaces" do
      # Collect the model data
      collector.collect

      # Check that the model was registered as a target for the commentable interface
      targets = collector.polymorphic_targets_for("commentable")
      expect(targets).not_to be_empty
      expect(targets[0].name).to eq("PostModel")
    end

    it "separates polymorphic and regular associations" do
      # Collect the model data
      collector.collect

      # Verify associations were categorized correctly
      polymorphic_assoc = collector.polymorphic_associations.find { |a| a[:association].options[:polymorphic] }
      expect(polymorphic_assoc).not_to be_nil
      expect(polymorphic_assoc[:association].options).to include(polymorphic: true)

      regular_assoc = collector.regular_associations.find { |a| a[:association].options == {} }
      expect(regular_assoc).not_to be_nil
      expect(regular_assoc[:association].options).not_to include(:polymorphic)
    end

    it "collects table information for models with tables" do
      # Collect the model data
      collector.collect

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

    it "collects isNullable for table columns" do
      # Collect the model data
      collector.collect

      # Verify isNullable was collected
      id_col_info = collector.tables["table_models"].find { |col| col.name == "id" }
      expect(id_col_info).not_to be_nil
      expect(id_col_info.isNullable).to be(false)
      expect(id_col_info.annotations).not_to include("NOT NULL")

      name_col_info = collector.tables["table_models"].find { |col| col.name == "name" }
      expect(name_col_info).not_to be_nil
      expect(name_col_info.isNullable).to be(true)
      expect(name_col_info.annotations).not_to include("NULL")
    end
  end

  describe "#register_invalid_association" do
    let(:test_model) { double("TestModel", name: "TestModel") }
    let(:test_assoc) { double("TestAssoc", name: "test_assoc") }

    it "adds invalid association to the tracker" do
      reason = "table does not exist"

      expect(collector.invalid_associations).to be_empty

      collector.register_invalid_association(test_model, test_assoc, reason)

      expect(collector.invalid_associations).not_to be_empty
      expect(collector.invalid_associations.size).to eq(1)

      invalid_assoc = collector.invalid_associations.first
      expect(invalid_assoc[:model]).to eq(test_model)
      expect(invalid_assoc[:association]).to eq(test_assoc)
      expect(invalid_assoc[:reason]).to eq(reason)
    end

    it "allows registering multiple invalid associations" do
      collector.register_invalid_association(test_model, test_assoc, "reason 1")
      collector.register_invalid_association(test_model, double("AnotherAssoc", name: "another_assoc"), "reason 2")

      expect(collector.invalid_associations.size).to eq(2)
    end

    it "accepts nil reason" do
      collector.register_invalid_association(test_model, test_assoc)

      invalid_assoc = collector.invalid_associations.first
      expect(invalid_assoc[:reason]).to be_nil
    end
  end

  describe "#update_foreign_keys" do
    it "adds FK annotations to foreign key columns" do
      # Set up a table with columns
      model = double("Model")
      id_column = double("IdColumn", name: "id", sql_type: "integer", type: :integer, null: false)
      fk_column = double("FkColumn", name: "user_id", sql_type: "integer", type: :integer, null: false)

      # Table collection setup
      allow(model).to receive_messages(reflect_on_all_associations: [], name: "Model", base_class: Object, "<": false, table_exists?: true, table_name: "models", columns: [id_column, fk_column], primary_key: "id")

      # Replace loader models
      allow(model_loader).to receive(:load).and_return([model])

      # First collect the table
      collector = described_class.new(model_loader)
      collector.collect

      # Create a mock relationship with FK information
      relationship = double(
        "Relationship",
        from_table: "models",
        to_table: "users",
        foreign_key: "user_id",
        fk_type: "belongs_to",
        fk_column: "user_id",
        fk_table: "models",
      )

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
      expect(targets).to contain_exactly(model1, model2)
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
