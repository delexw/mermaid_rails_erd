# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::ColumnInfo do
  describe "#initialize" do
    it "sets attributes from parameters" do
      column_info = described_class.new("integer", "id", ["PK"])
      
      expect(column_info.name).to eq("id")
      expect(column_info.type).to eq("integer")
      expect(column_info.annotations).to eq(["PK"])
    end
    
    it "initializes annotations as an empty array when not provided" do
      column_info = described_class.new("varchar", "email")
      
      expect(column_info.annotations).to eq([])
    end
  end
end 