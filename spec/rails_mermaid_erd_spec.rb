# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsMermaidErd do
  it "has a version number" do
    expect(RailsMermaidErd::VERSION).not_to be_nil
  end

  describe ".build" do
    it "creates a new generator and collects data" do
      # Mock the Generator
      generator = instance_double(RailsMermaidErd::Generator)
      allow(RailsMermaidErd::Generator).to receive(:new).and_return(generator)
      allow(generator).to receive(:build).and_return(generator)

      expect(described_class.build).to eq(generator)
    end
  end

  describe ".generate" do
    it "uses build and emit to generate the diagram" do
      # Mock the Generator
      generator = instance_double(RailsMermaidErd::Generator)
      allow(described_class).to receive(:build).and_return(generator)
      allow(generator).to receive(:emit).with(output: $stdout)

      described_class.generate

      expect(described_class).to have_received(:build)
      expect(generator).to have_received(:emit).with(output: $stdout)
    end

    it "passes custom output to emit" do
      # Mock the Generator
      generator = instance_double(RailsMermaidErd::Generator)
      custom_output = StringIO.new

      allow(described_class).to receive(:build).and_return(generator)
      allow(generator).to receive(:emit).with(output: custom_output)

      described_class.generate(output: custom_output)

      expect(described_class).to have_received(:build)
      expect(generator).to have_received(:emit).with(output: custom_output)
    end
  end
end
