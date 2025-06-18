# frozen_string_literal: true

require "spec_helper"

RSpec.describe MermaidRailsErd::Relationship do
  describe "#initialize" do
    it "sets attributes from parameters" do
      relationship = described_class.new(
        "posts",
        "users",
        "user_id",
        "||--o{",
        "posts.user_id FK → users.id PK",
      )

      expect(relationship.from_table).to eq("posts")
      expect(relationship.to_table).to eq("users")
      expect(relationship.foreign_key).to eq("user_id")
      expect(relationship.relationship_type).to eq("||--o{")
      expect(relationship.label).to eq("posts.user_id FK → users.id PK")
    end
  end

  describe "#key" do
    it "generates a sorted key from tables and foreign key" do
      relationship = described_class.new(
        "orders",
        "customers",
        "customer_id",
        "||--o{",
        "orders.customer_id FK → customers.id PK",
      )

      # The key should be sorted alphabetically
      expected_key = %w[customers customer_id orders].sort.join("::")
      expect(relationship.key).to eq(expected_key)
    end
  end
end
