# frozen_string_literal: true

require "spec_helper"

RSpec.describe MermaidRailsErd::ModelLoader do
  describe "#load" do
    let(:loader) { described_class.new }

    context "when Rails is loaded" do
      let(:model_class1) { double("ModelClass1") }
      let(:model_class2) { double("ModelClass2") }
      let(:rails_application) { double("RailsApplication") }
      let(:rails_config) { double("RailsConfig") }

      before do
        # Set up Rails mock
        stub_const("Rails", double("Rails", application: rails_application, configuration: rails_config))

        # Mock configuration
        allow(rails_config).to receive(:cache_classes).and_return(false)

        # Mock eager loading
        allow(rails_application).to receive(:eager_load!)

        # Mock ActiveRecord
        stub_const("ActiveRecord::Base", double("ActiveRecordBase", descendants: [model_class1, model_class2, ActiveRecord::Base]))

        # Set up model class mocks
        allow(model_class1).to receive(:abstract_class?).and_return(false)
        allow(model_class2).to receive(:abstract_class?).and_return(false)
        allow(ActiveRecord::Base).to receive(:abstract_class?).and_return(true)
      end

      it "eager loads the application" do
        expect(rails_application).to receive(:eager_load!)

        loader.load
      end

      it "returns all ActiveRecord model classes except ActiveRecord::Base" do
        models = loader.load

        expect(models).to contain_exactly(model_class1, model_class2)
        expect(models).not_to include(ActiveRecord::Base)
      end

      it "excludes abstract classes" do
        abstract_model = double("AbstractModel")
        allow(ActiveRecord::Base).to receive(:descendants).and_return([model_class1, model_class2, ActiveRecord::Base, abstract_model])
        allow(abstract_model).to receive(:abstract_class?).and_return(true)

        models = loader.load

        expect(models).to contain_exactly(model_class1, model_class2)
        expect(models).not_to include(abstract_model)
      end

      it "doesn't eager load if cache_classes is true" do
        allow(rails_config).to receive(:cache_classes).and_return(true)
        expect(rails_application).not_to receive(:eager_load!)

        loader.load
      end
    end

    context "when Rails is not loaded" do
      before do
        hide_const("Rails")
      end

      it "raises an error" do
        expect { loader.load }.to raise_error(MermaidRailsErd::Error, /Rails is not loaded/)
      end
    end
  end
end
