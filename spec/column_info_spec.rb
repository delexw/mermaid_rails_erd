# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::ColumnInfo do
  describe "#initialize" do
    it "sets attributes from parameters" do
      column_info = described_class.new("id", ["PK"])

      expect(column_info.name).to eq("id")
      expect(column_info.annotations).to eq(["PK"])
    end

    it "initializes annotations as an empty array when not provided" do
      column_info = described_class.new("email")

      expect(column_info.annotations).to eq([])
    end

    it "sets isNullable when provided" do
      column_info = described_class.new("email", [], "varchar(255)", :string, true)

      expect(column_info.isNullable).to be(true)
    end

    it "sets isNullable to nil when not provided" do
      column_info = described_class.new("email")

      expect(column_info.isNullable).to be_nil
    end

    it "sets all attributes including isNullable" do
      column_info = described_class.new("user_id", ["FK"], "int(11)", :integer, false)

      expect(column_info.name).to eq("user_id")
      expect(column_info.annotations).to eq(["FK"])
      expect(column_info.raw_sql_type).to eq("int(11)")
      expect(column_info.activerecord_type).to eq(:integer)
      expect(column_info.isNullable).to be(false)
    end
  end
end
