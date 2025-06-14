# frozen_string_literal: true

RSpec.describe RailsMermaidErd do
  it "has a version number" do
    expect(RailsMermaidErd::VERSION).not_to be nil
  end

  describe ".generate" do
    context "when Rails is not loaded" do
      it "raises an error" do
        expect { described_class.generate }.to raise_error(RailsMermaidErd::Error)
      end
    end
  end
end 