# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::PolymorphicTargetsResolver do
  let(:model_data_collector) { double("ModelDataCollector") }
  let(:resolver) { described_class.new(model_data_collector) }
  
  describe "#resolve" do
    let(:models) do
      [
        double("PostModel"), 
        double("ArticleModel"),
        double("CommentModel"),
        double("UserModel")
      ]
    end
    
    before do
      # Set up the model_data_collector to return appropriate polymorphic targets
      allow(model_data_collector).to receive(:polymorphic_targets_for).with("commentable").and_return([models[0], models[1]])
      allow(model_data_collector).to receive(:polymorphic_targets_for).with("likeable").and_return([models[2]])
      allow(model_data_collector).to receive(:polymorphic_targets_for).with("unknown_interface").and_return([])
      
      # Set up table_name for models
      allow(models[0]).to receive(:table_name).and_return("posts")
      allow(models[1]).to receive(:table_name).and_return("articles")
      allow(models[2]).to receive(:table_name).and_return("comments")
      allow(models[3]).to receive(:table_name).and_return("users")
    end
    
    it "returns relationships for models implementing a specific interface" do
      relationships = resolver.resolve("commentable", "comments", "||--o{")
      
      expect(relationships.size).to eq(2)
      expect(relationships.map(&:to_table)).to include("posts")
      expect(relationships.map(&:to_table)).to include("articles")
    end
    
    it "returns empty array for unknown interface" do
      relationships = resolver.resolve("unknown_interface", "comments", "||--o{")
      
      expect(relationships).to be_empty
    end
    
    it "returns only relationships for models implementing the specified interface" do
      relationships = resolver.resolve("likeable", "reactions", "||--o{")
      
      expect(relationships.size).to eq(1)
      expect(relationships.first.to_table).to eq("comments")
    end
    
    it "returns empty array when no models implement the interface" do
      # Reset the model_data_collector to return empty array
      allow(model_data_collector).to receive(:polymorphic_targets_for).with("commentable").and_return([])
      
      relationships = resolver.resolve("commentable", "comments", "||--o{")
      
      expect(relationships).to be_empty
    end
  end
end 