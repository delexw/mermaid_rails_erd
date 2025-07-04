# frozen_string_literal: true

require "spec_helper"

RSpec.describe MermaidRailsErd::MermaidEmitter do
  let(:output) { StringIO.new }
  let(:emitter) { described_class.new(output, tables, relationships) }

  describe "#emit" do
    context "with tables and relationships" do
      let(:tables) do
        {
          "users" => [
            MermaidRailsErd::ColumnInfo.new("id", ["PK"], "int(11)", :integer),
            MermaidRailsErd::ColumnInfo.new("email", [], "varchar(255)", :string),
            MermaidRailsErd::ColumnInfo.new("name", [], "varchar(255)", :string),
          ],
          "posts" => [
            MermaidRailsErd::ColumnInfo.new("id", ["PK"], "int(11)", :integer),
            MermaidRailsErd::ColumnInfo.new("user_id", ["FK"], "int(11)", :integer),
            MermaidRailsErd::ColumnInfo.new("title", [], "varchar(255)", :string),
            MermaidRailsErd::ColumnInfo.new("content", [], "text", :text),
          ],
          "comments" => [
            MermaidRailsErd::ColumnInfo.new("id", ["PK"], "int(11)", :integer),
            MermaidRailsErd::ColumnInfo.new("post_id", ["FK"], "int(11)", :integer),
            MermaidRailsErd::ColumnInfo.new("user_id", ["FK"], "int(11)", :integer),
            MermaidRailsErd::ColumnInfo.new("body", [], "text", :text),
          ],
        }
      end

      let(:relationships) do
        [
          MermaidRailsErd::Relationship.new(
            "posts", "users", "user_id", "||--o{", nil,
            "posts", "user_id", "users", "id"
          ),
          MermaidRailsErd::Relationship.new(
            "comments", "posts", "post_id", "||--o{", nil,
            "comments", "post_id", "posts", "id"
          ),
          MermaidRailsErd::Relationship.new(
            "comments", "users", "user_id", "||--o{", nil,
            "comments", "user_id", "users", "id"
          ),
        ]
      end

      it "emits the ERD diagram header" do
        emitter.emit
        expect(output.string).to include("erDiagram")
      end

      it "emits table definitions with columns" do
        emitter.emit
        expect(output.string).to include("users {")
        expect(output.string).to include("integer id")
        expect(output.string).to include("string email")
      end

      it "includes column annotations" do
        emitter.emit
        expect(output.string).to include("integer id PK")
        expect(output.string).to include("integer user_id FK")
      end

      it "emits relationship definitions" do
        emitter.emit
        expect(output.string).to include("posts #{relationships[0].relationship_type} users")
        expect(output.string).to include("comments #{relationships[1].relationship_type} posts")
        expect(output.string).to include("comments #{relationships[2].relationship_type} users")
      end
    end

    context "with empty tables" do
      let(:tables) { {} }
      let(:relationships) { [] }

      it "emits only the ERD diagram header" do
        emitter.emit
        expect(output.string.strip).to eq("erDiagram")
      end
    end
  end
end
