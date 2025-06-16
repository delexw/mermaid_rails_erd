# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::AssociationResolver do
  describe "#resolve" do
    let(:resolver) { described_class.new }
    
    context "with an association that has a table_name method" do
      let(:assoc) { double("Association") }
      
      before do
        allow(assoc).to receive(:respond_to?).with(:table_name).and_return(true)
        allow(assoc).to receive(:table_name).and_return("posts")
        
        # Mock ActiveRecord connection
        stub_const("ActiveRecord::Base", double("ActiveRecordBase"))
        allow(ActiveRecord::Base).to receive(:connection).and_return(double("Connection"))
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).with("posts").and_return(true)
        allow(ActiveRecord::Base.connection).to receive(:primary_key).with("posts").and_return("id")
      end
      
      it "returns a hash with table_name and primary_key" do
        result = resolver.resolve(assoc)
        
        expect(result).to be_a(Hash)
        expect(result[:table_name]).to eq("posts")
        expect(result[:primary_key]).to eq("id")
      end
    end
    
    context "with an association that has table_name in options" do
      let(:assoc) { double("Association", options: { table_name: "custom_posts" }) }
      
      before do
        allow(assoc).to receive(:respond_to?).with(:table_name).and_return(false)
        
        # Mock ActiveRecord connection
        stub_const("ActiveRecord::Base", double("ActiveRecordBase"))
        allow(ActiveRecord::Base).to receive(:connection).and_return(double("Connection"))
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).with("custom_posts").and_return(true)
        allow(ActiveRecord::Base.connection).to receive(:primary_key).with("custom_posts").and_return("id")
      end
      
      it "uses the table_name from options" do
        result = resolver.resolve(assoc)
        
        expect(result).to be_a(Hash)
        expect(result[:table_name]).to eq("custom_posts")
        expect(result[:primary_key]).to eq("id")
      end
    end
    
    context "with an association that uses plural_name" do
      let(:assoc) { double("Association", options: {}, plural_name: "comments") }
      
      before do
        allow(assoc).to receive(:respond_to?).with(:table_name).and_return(false)
        
        # Mock ActiveRecord connection
        stub_const("ActiveRecord::Base", double("ActiveRecordBase"))
        allow(ActiveRecord::Base).to receive(:connection).and_return(double("Connection"))
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).with("comments").and_return(true)
        allow(ActiveRecord::Base.connection).to receive(:primary_key).with("comments").and_return("id")
      end
      
      it "uses the plural_name" do
        result = resolver.resolve(assoc)
        
        expect(result).to be_a(Hash)
        expect(result[:table_name]).to eq("comments")
        expect(result[:primary_key]).to eq("id")
      end
    end
    
    context "when table doesn't exist" do
      let(:assoc) { double("Association", options: {}, plural_name: "nonexistent_tables") }
      
      before do
        allow(assoc).to receive(:respond_to?).with(:table_name).and_return(false)
        
        # Mock ActiveRecord connection
        stub_const("ActiveRecord::Base", double("ActiveRecordBase"))
        allow(ActiveRecord::Base).to receive(:connection).and_return(double("Connection"))
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).with("nonexistent_tables").and_return(false)
      end
      
      it "returns nil" do
        result = resolver.resolve(assoc)
        
        expect(result).to be_nil
      end
    end
    
    context "when table_name method raises an error" do
      let(:assoc) { double("Association", options: {}, plural_name: "fallback_tables") }
      
      before do
        allow(assoc).to receive(:respond_to?).with(:table_name).and_return(true)
        allow(assoc).to receive(:table_name).and_raise(StandardError.new("Table error"))
        
        # Mock ActiveRecord connection
        stub_const("ActiveRecord::Base", double("ActiveRecordBase"))
        allow(ActiveRecord::Base).to receive(:connection).and_return(double("Connection"))
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).with("fallback_tables").and_return(true)
        allow(ActiveRecord::Base.connection).to receive(:primary_key).with("fallback_tables").and_return("id")
      end
      
      it "falls back to plural_name" do
        result = resolver.resolve(assoc)
        
        expect(result).to be_a(Hash)
        expect(result[:table_name]).to eq("fallback_tables")
        expect(result[:primary_key]).to eq("id")
      end
    end
  end
end 