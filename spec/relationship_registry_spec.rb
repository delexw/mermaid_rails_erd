# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::RelationshipRegistry do
  let(:symbol_mapper) { double("SymbolMapper") }
  let(:association_resolver) { double("AssociationResolver") }
  let(:polymorphic_resolver) { double("PolymorphicResolver") }
  let(:model_data_collector) { double("ModelDataCollector") }
  
  let(:registry) { 
    described_class.new(
      symbol_mapper: symbol_mapper,
      association_resolver: association_resolver,
      polymorphic_resolver: polymorphic_resolver
    ) 
  }
  
  before do
    allow(polymorphic_resolver).to receive(:model_data_collector).and_return(model_data_collector)
  end
end 