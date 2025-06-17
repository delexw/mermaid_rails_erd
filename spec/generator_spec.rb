# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::Generator do
  let(:output) { StringIO.new }

  # Mock the ModelLoader for all tests
  before do
    # Create a stub ModelLoader class that doesn't need Rails
    model_loader = double("ModelLoader", load: [])
    allow(RailsMermaidErd::ModelLoader).to receive(:new).and_return(model_loader)
  end

  describe "#build" do
    it "collects model data and relationships" do
      # Mock the dependencies
      model_data_collector = double("ModelDataCollector")
      relationship_registry = double("RelationshipRegistry")

      # Create a valid generator instance with mocked dependencies
      generator = described_class.new
      generator.instance_variable_set(:@model_data_collector, model_data_collector)
      generator.instance_variable_set(:@relationship_registry, relationship_registry)

      # Mock the behavior
      expect(model_data_collector).to receive(:collect).and_return(model_data_collector)
      expect(relationship_registry).to receive(:build_all_relationships).and_return([])
      expect(model_data_collector).to receive(:update_foreign_keys).with([]).and_return({})

      # Verify the method returns self
      expect(generator.build).to eq(generator)
    end

    it "handles exceptions during relationship building" do
      # Mock the dependencies
      model_data_collector = double("ModelDataCollector")
      relationship_registry = double("RelationshipRegistry")

      # Create a valid generator instance with mocked dependencies
      generator = described_class.new
      generator.instance_variable_set(:@model_data_collector, model_data_collector)
      generator.instance_variable_set(:@relationship_registry, relationship_registry)

      # Mock the error behavior
      expect(model_data_collector).to receive(:collect)
      expect(relationship_registry).to receive(:build_all_relationships).and_raise(StandardError.new("Test error"))
      expect(model_data_collector).to receive(:update_foreign_keys).with([]).and_return({})

      # Should not raise an error
      expect { generator.build }.not_to raise_error

      # Should set relationships to an empty array in parsed_data
      expect(generator.parsed_data.relationships).to eq([])
    end
  end

  describe "#emit" do
    it "creates a MermaidEmitter with the collected data" do
      generator = described_class.new
      tables = { "users" => [] }
      relationships = [double("Relationship")]
      output = StringIO.new

      generator.instance_variable_set(:@tables, tables)
      generator.instance_variable_set(:@relationships, relationships)

      emitter = double("MermaidEmitter")
      expect(RailsMermaidErd::MermaidEmitter).to receive(:new).with(output, tables, relationships).and_return(emitter)
      expect(emitter).to receive(:emit)

      generator.emit(output: output)
    end

    it "uses the output from initialization if none is provided" do
      output = StringIO.new
      generator = described_class.new(output: output)
      tables = { "users" => [] }
      relationships = [double("Relationship")]

      generator.instance_variable_set(:@tables, tables)
      generator.instance_variable_set(:@relationships, relationships)

      emitter = double("MermaidEmitter")
      expect(RailsMermaidErd::MermaidEmitter).to receive(:new).with(output, tables, relationships).and_return(emitter)
      expect(emitter).to receive(:emit)

      generator.emit
    end
  end

  describe "#parsed_data" do
    it "returns a ParsedData struct with delegated methods" do
      generator = described_class.new

      # Mock the build process
      allow(generator).to receive(:build).and_return(generator)
      relationships = [double("Relationship")]
      tables = { "users" => [double("Column")] }

      # Build the data first
      generator.instance_variable_set(:@relationships, relationships)
      generator.instance_variable_set(:@tables, tables)

      parsed_data = generator.parsed_data

      expect(parsed_data).to be_a(RailsMermaidErd::ParsedData)
      expect(parsed_data.relationships).to eq(relationships)
      expect(parsed_data.tables).to eq(tables)

      # Test delegation to model_data_collector
      expect(parsed_data).to respond_to(:invalid_associations)
      expect(parsed_data).to respond_to(:models_data)
      expect(parsed_data).to respond_to(:models_no_tables)
      expect(parsed_data).to respond_to(:models)
      expect(parsed_data).to respond_to(:polymorphic_associations)
      expect(parsed_data).to respond_to(:regular_associations)
    end
  end
end
