# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::Generator do
  describe "#generate" do
    let(:output) { StringIO.new }
    let(:generator) { described_class.new(output: output) }
    let(:models) { [double("Model")] }
    let(:filtered_models) { models }
    let(:collector) { instance_double(RailsMermaidErd::ModelDataCollector) }
    let(:registry) { instance_double(RailsMermaidErd::RelationshipRegistry) }
    let(:relationships) { [double("Relationship")] }
    let(:tables) { { "table1" => double("Table1") } }
    let(:emitter) { instance_double(RailsMermaidErd::MermaidEmitter) }
    let(:model_loader) { instance_double(RailsMermaidErd::ModelLoader) }
    let(:polymorphic_resolver) { double("PolymorphicResolver") }
    
    before do
      # Mock the model loader
      allow(RailsMermaidErd::ModelLoader).to receive(:new).and_return(model_loader)
      allow(model_loader).to receive(:load).and_return(models)
      
      # Setup the model filtering expectations
      allow(models[0]).to receive(:base_class).and_return(models[0])
      allow(models[0]).to receive(:<).and_return(false)
      allow(models[0]).to receive(:table_exists?).and_return(true)
      
      # Mock the collector and registry
      allow(RailsMermaidErd::ModelDataCollector).to receive(:new).and_return(collector)
      allow(RailsMermaidErd::PolymorphicTargetsResolver).to receive(:new).and_return(polymorphic_resolver)
      allow(polymorphic_resolver).to receive(:model_data_collector).and_return(collector)
      allow(RailsMermaidErd::RelationshipRegistry).to receive(:new).and_return(registry)
      
      # Set up collector expectations
      allow(collector).to receive(:collect).with(filtered_models)
      allow(collector).to receive(:update_foreign_keys).with(relationships).and_return(tables)
      
      # Set up registry expectations
      allow(registry).to receive(:build_all_relationships).with(filtered_models).and_return(relationships)
      
      # Mock the emitter
      allow(RailsMermaidErd::MermaidEmitter).to receive(:new).with(output, tables, relationships).and_return(emitter)
      allow(emitter).to receive(:emit)
    end
    
    it "loads models using the ModelLoader" do
      expect(model_loader).to receive(:load)
      
      generator.generate
    end
    
    it "collects model data" do
      expect(collector).to receive(:collect).with(filtered_models)
      
      generator.generate
    end
    
    it "builds relationships from associations" do
      expect(registry).to receive(:build_all_relationships).with(filtered_models)
      
      generator.generate
    end
    
    it "updates foreign keys on the collector" do
      expect(collector).to receive(:update_foreign_keys).with(relationships)
      
      generator.generate
    end
    
    it "emits the ERD diagram through the MermaidEmitter" do
      expect(RailsMermaidErd::MermaidEmitter).to receive(:new).with(output, tables, relationships).and_return(emitter)
      expect(emitter).to receive(:emit)
      
      generator.generate
    end
    
    it "passes custom output to the emitter" do
      custom_output = StringIO.new
      custom_generator = described_class.new(output: custom_output)
      
      expect(RailsMermaidErd::MermaidEmitter).to receive(:new).with(custom_output, tables, relationships).and_return(emitter)
      
      allow(RailsMermaidErd::ModelLoader).to receive(:new).and_return(model_loader)
      allow(RailsMermaidErd::ModelDataCollector).to receive(:new).and_return(collector)
      allow(RailsMermaidErd::PolymorphicTargetsResolver).to receive(:new).and_return(polymorphic_resolver)
      allow(RailsMermaidErd::RelationshipRegistry).to receive(:new).and_return(registry)
      
      custom_generator.generate
    end
  end
end 