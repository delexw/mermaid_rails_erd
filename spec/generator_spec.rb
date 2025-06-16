# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::Generator do
  describe "#generate" do
    let(:output) { StringIO.new }
    let(:generator) { described_class.new(output: output) }
    let(:models) { [double("Model")] }
    let(:collector) { instance_double(RailsMermaidErd::ModelDataCollector) }
    let(:registry) { instance_double(RailsMermaidErd::RelationshipRegistry) }
    let(:relationships) { [double("Relationship")] }
    let(:tables) { { "table1" => double("Table1") } }
    let(:emitter) { instance_double(RailsMermaidErd::MermaidEmitter) }
    let(:model_loader) { instance_double(RailsMermaidErd::ModelLoader) }
    let(:polymorphic_resolver) { double("PolymorphicResolver") }
    let(:symbol_mapper) { double("SymbolMapper") }
    let(:association_resolver) { double("AssociationResolver") }
    
    before do
      # Mock the model loader
      allow(RailsMermaidErd::ModelLoader).to receive(:new).and_return(model_loader)
      allow(model_loader).to receive(:load).and_return(models)
      
      # Setup the model filtering expectations
      allow(models[0]).to receive(:base_class).and_return(models[0])
      allow(models[0]).to receive(:<).and_return(false)
      allow(models[0]).to receive(:table_exists?).and_return(true)
      
      # Mock the collector and registry
      allow(RailsMermaidErd::ModelDataCollector).to receive(:new).with(model_loader).and_return(collector)
      allow(RailsMermaidErd::PolymorphicTargetsResolver).to receive(:new).and_return(polymorphic_resolver)
      allow(polymorphic_resolver).to receive(:model_data_collector).and_return(collector)
      
      allow(RailsMermaidErd::RelationshipSymbolMapper).to receive(:new).and_return(symbol_mapper)
      allow(RailsMermaidErd::AssociationResolver).to receive(:new).and_return(association_resolver)
      
      allow(RailsMermaidErd::RelationshipRegistry).to receive(:new).with(
        symbol_mapper: symbol_mapper,
        association_resolver: association_resolver,
        polymorphic_resolver: polymorphic_resolver,
        printed_tables: instance_of(Set),
        model_data_collector: collector
      ).and_return(registry)
      
      # Set up collector expectations
      allow(collector).to receive(:collect).and_return(collector)
      allow(collector).to receive(:update_foreign_keys).with(relationships).and_return(tables)
      
      # Set up registry expectations
      allow(registry).to receive(:build_all_relationships).and_return(relationships)
      
      # Mock the emitter
      allow(RailsMermaidErd::MermaidEmitter).to receive(:new).with(output, tables, relationships).and_return(emitter)
      allow(emitter).to receive(:emit)
    end
    
    it "collects model data" do
      expect(collector).to receive(:collect)
      
      generator.generate
    end
    
    it "builds relationships from associations" do
      expect(registry).to receive(:build_all_relationships)
      
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
      allow(RailsMermaidErd::ModelDataCollector).to receive(:new).with(model_loader).and_return(collector)
      allow(RailsMermaidErd::PolymorphicTargetsResolver).to receive(:new).and_return(polymorphic_resolver)
      allow(RailsMermaidErd::RelationshipSymbolMapper).to receive(:new).and_return(symbol_mapper)
      allow(RailsMermaidErd::AssociationResolver).to receive(:new).and_return(association_resolver)
      allow(RailsMermaidErd::RelationshipRegistry).to receive(:new).with(
        symbol_mapper: symbol_mapper,
        association_resolver: association_resolver,
        polymorphic_resolver: polymorphic_resolver,
        printed_tables: instance_of(Set),
        model_data_collector: collector
      ).and_return(registry)
      
      custom_generator.generate
    end
  end
end 