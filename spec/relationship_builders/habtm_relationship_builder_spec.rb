# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd::RelationshipBuilders::HasAndBelongsToManyRelationshipBuilder do
  let(:symbol_mapper) { double("SymbolMapper") }
  let(:association_resolver) { double("AssociationResolver") }
  let(:printed_tables) { Set.new }
  let(:builder) { described_class.new(symbol_mapper: symbol_mapper, association_resolver: association_resolver, printed_tables: printed_tables) }

  describe "#build" do
    context "with standard HABTM association" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      let(:models) { [] }
      let(:connection) { double("Connection") }

      before do
        allow(model).to receive(:table_name).and_return("authors")
        allow(model).to receive(:name).and_return("Author")
        allow(model).to receive(:primary_key).and_return("id")
        
        allow(assoc).to receive(:name).and_return("books")
        allow(assoc).to receive(:join_table).and_return("authors_books")
        allow(assoc).to receive(:foreign_key).and_return("author_id")
        allow(assoc).to receive(:association_foreign_key).and_return("book_id")
        
        to_table_info = { table_name: "books", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        # Mock ActiveRecord connection
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
        allow(connection).to receive(:columns).with("authors_books").and_return([])
        
        allow(symbol_mapper).to receive(:map).with(:has_and_belongs_to_many).and_return("}o--||")
      end

      it "creates relationships for both sides of the join" do
        relationships = builder.build(model, assoc, models)
        
        expect(relationships.size).to eq(2)
        
        # First relationship (join table to model)
        expect(relationships[0].from_table).to eq("authors_books")
        expect(relationships[0].to_table).to eq("authors")
        expect(relationships[0].foreign_key).to eq("author_id")
        expect(relationships[0].relationship_type).to eq("}o--||")
        expect(relationships[0].label).to eq("authors_books.author_id FK → authors.id PK")
        
        # Second relationship (join table to associated model)
        expect(relationships[1].from_table).to eq("authors_books")
        expect(relationships[1].to_table).to eq("books")
        expect(relationships[1].foreign_key).to eq("book_id")
        expect(relationships[1].relationship_type).to eq("}o--||")
        expect(relationships[1].label).to eq("authors_books.book_id FK → books.id PK")
      end
    end
    
    context "with custom join table name" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      let(:models) { [] }
      let(:connection) { double("Connection") }

      before do
        allow(model).to receive(:table_name).and_return("students")
        allow(model).to receive(:name).and_return("Student")
        allow(model).to receive(:primary_key).and_return("id")
        
        allow(assoc).to receive(:name).and_return("courses")
        allow(assoc).to receive(:join_table).and_return("enrollments")
        allow(assoc).to receive(:foreign_key).and_return("student_id")
        allow(assoc).to receive(:association_foreign_key).and_return("course_id")
        
        to_table_info = { table_name: "courses", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        # Mock ActiveRecord connection
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
        allow(connection).to receive(:columns).with("enrollments").and_return([])
      end

      it "uses the custom join table name" do
        relationships = builder.build(model, assoc, models)
        
        expect(relationships[0].from_table).to eq("enrollments")
        expect(relationships[1].from_table).to eq("enrollments")
      end
    end

    context "when join table does not exist" do
      let(:model) { double("Model") }
      let(:assoc) { double("Association") }
      let(:models) { [] }

      before do
        allow(model).to receive(:table_name).and_return("teachers")
        allow(model).to receive(:name).and_return("Teacher")
        
        allow(assoc).to receive(:name).and_return("subjects")
        allow(assoc).to receive(:join_table).and_return("subjects_teachers")
        
        to_table_info = { table_name: "subjects", primary_key: "id" }
        allow(association_resolver).to receive(:resolve).with(assoc).and_return(to_table_info)
        
        # Mock ActiveRecord connection to throw an error
        allow(ActiveRecord::Base).to receive(:connection).and_raise(StandardError.new("Table doesn't exist"))
        
        # Mock the log_missing_table_warning method
        allow(builder).to receive(:log_missing_table_warning).and_return([])
      end

      it "logs a warning and returns an empty array" do
        expect(builder).to receive(:log_missing_table_warning)
        relationships = builder.build(model, assoc, models)
        expect(relationships).to eq([])
      end
    end
  end
end 