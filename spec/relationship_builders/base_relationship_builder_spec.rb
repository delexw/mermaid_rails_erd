# frozen_string_literal: true

require "spec_helper"

# Define a custom error class for testing
class TestError < StandardError; end

RSpec.describe MermaidRailsErd::RelationshipBuilders::BaseRelationshipBuilder do
  let(:symbol_mapper) { double("SymbolMapper") }
  let(:association_resolver) { double("AssociationResolver") }
  let(:model_data_collector) { double("ModelDataCollector") }
  let(:builder) { described_class.new(symbol_mapper: symbol_mapper, association_resolver: association_resolver, model_data_collector: model_data_collector) }

  describe "#build" do
    it "raises NotImplementedError" do
      model = double("Model")
      assoc = double("Association")
      expect { builder.build(model, assoc) }.to raise_error(NotImplementedError)
    end
  end

  describe "#resolve_association_model" do
    let(:model) { double("Model", name: "TestModel") }
    let(:assoc) { double("Association", name: "test_assoc") }

    it "delegates to association_resolver" do
      expected_result = { table_name: "test_table" }
      expect(association_resolver).to receive(:resolve).with(assoc).and_return(expected_result)

      result = builder.send(:resolve_association_model, model, assoc)
      expect(result).to eq(expected_result)
    end

    it "handles errors, registers invalid association and returns nil" do
      error_message = "Test error"
      allow(association_resolver).to receive(:resolve).with(assoc).and_raise(StandardError.new(error_message))

      # Expect the model_data_collector to register the invalid association
      expect(model_data_collector).to receive(:register_invalid_association).with(
        model, assoc, "StandardError - #{error_message}"
      )

      result = builder.send(:resolve_association_model, model, assoc)
      expect(result).to be_nil
    end
  end

  describe "#safe_foreign_key" do
    let(:model) { double("Model", name: "TestModel") }

    it "returns nil for through associations" do
      assoc = double("Association", options: { through: :other_model })
      expect(builder.send(:safe_foreign_key, model, assoc)).to be_nil
    end

    it "returns foreign_key for regular associations" do
      assoc = double("Association", options: {}, foreign_key: "test_id")
      expect(builder.send(:safe_foreign_key, model, assoc)).to eq("test_id")
    end

    it "handles errors, registers invalid association and returns nil" do
      assoc = double("Association", options: {}, name: "test_assoc")
      error = TestError.new("Foreign key error")

      # Use our custom error instead of NoMethodError
      allow(assoc).to receive(:foreign_key).and_raise(error)

      # Expect the model_data_collector to register the invalid association
      expect(model_data_collector).to receive(:register_invalid_association).with(
        model, assoc, "Cannot determine foreign key: TestError - Foreign key error"
      )

      # Explicitly call without the allow statements that were breaking our test
      expect(builder.send(:safe_foreign_key, model, assoc)).to be_nil
    end
  end

  describe "#skip_duplicate_one_to_one?" do
    let(:model) { double("Model", table_name: "models") }
    let(:to_table_info) { { table_name: "related_models" } }

    it "returns false for has_many associations" do
      assoc = double("Association", macro: :has_many, options: {})
      expect(builder.send(:skip_duplicate_one_to_one?, model, assoc, to_table_info)).to be false
    end

    it "returns false for polymorphic associations" do
      assoc = double("Association", macro: :belongs_to, options: { polymorphic: true })
      expect(builder.send(:skip_duplicate_one_to_one?, model, assoc, to_table_info)).to be false
    end

    it "returns false for first occurrence of a one-to-one relationship" do
      assoc = double("Association", macro: :has_one, options: {})
      expect(builder.send(:skip_duplicate_one_to_one?, model, assoc, to_table_info)).to be false
    end

    it "returns true for duplicate one-to-one relationships" do
      assoc = double("Association", macro: :has_one, options: {})
      # First call adds to the set
      builder.send(:skip_duplicate_one_to_one?, model, assoc, to_table_info)
      # Second call should return true
      expect(builder.send(:skip_duplicate_one_to_one?, model, assoc, to_table_info)).to be true
    end
  end

  describe "#log_missing_table_warning" do
    let(:model) { double("Model", name: "TestModel") }
    let(:assoc) { double("Association", name: "test_assoc", options: {}) }

    it "registers the invalid association with the collector" do
      reason = "table does not exist"

      # Expect the model_data_collector to register the invalid association
      expect(model_data_collector).to receive(:register_invalid_association).with(model, assoc, reason)

      result = builder.send(:log_missing_table_warning, model, assoc, reason)
      expect(result).to eq([])
    end

    it "handles associations with class_name option" do
      class_name = "CustomClass"
      assoc = double("Association", name: "test_assoc", options: { class_name: class_name })
      reason = "table does not exist"

      # Expect the model_data_collector to register the invalid association
      expect(model_data_collector).to receive(:register_invalid_association).with(model, assoc, reason)

      result = builder.send(:log_missing_table_warning, model, assoc, reason)
      expect(result).to eq([])
    end
  end

  describe "#register_invalid_association" do
    let(:model) { double("Model", name: "TestModel") }
    let(:assoc) { double("Association", name: "test_assoc") }

    it "calls register_invalid_association on model_data_collector" do
      reason = "test reason"

      expect(model_data_collector).to receive(:register_invalid_association).with(model, assoc, reason)

      builder.send(:register_invalid_association, model, assoc, reason)
    end

    it "doesn't fail if model_data_collector is nil" do
      builder_without_collector = described_class.new(
        symbol_mapper: symbol_mapper,
        association_resolver: association_resolver,
      )

      # Should not raise an error
      expect do
        builder_without_collector.send(:register_invalid_association, model, assoc, "test reason")
      end.not_to raise_error
    end
  end
end
