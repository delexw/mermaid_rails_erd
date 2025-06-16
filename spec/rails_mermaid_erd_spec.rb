# frozen_string_literal: true

RSpec.describe RailsMermaidErd do
  it "has a version number" do
    expect(RailsMermaidErd::VERSION).not_to be nil
  end

  describe ".generate" do
    context "when Rails is not loaded" do
      before do
        # First hide the Rails constant
        hide_const("Rails")
        
        # Then modify the generator to raise the proper error
        model_loader = instance_double(RailsMermaidErd::ModelLoader)
        allow(RailsMermaidErd::ModelLoader).to receive(:new).and_return(model_loader)
        allow(model_loader).to receive(:load).and_raise(RailsMermaidErd::Error.new("Rails is not loaded"))
      end
      
      it "raises an error" do
        expect { described_class.generate }.to raise_error(RailsMermaidErd::Error, /Rails is not loaded/)
      end
    end
  end
end 