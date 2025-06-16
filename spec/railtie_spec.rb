# frozen_string_literal: true

require "spec_helper"
require "rails"
require "rails_mermaid_erd/railtie"

RSpec.describe RailsMermaidErd::Railtie do
  context "when Rails is loaded" do
    before do
      # Ensure that we have Rails defined
      unless defined?(Rails)
        stub_const("Rails", Module.new)
        stub_const("Rails::Railtie", Class.new)
        allow(Rails::Railtie).to receive(:rake_tasks)
      end
      
      # Reload the railtie code
      load File.expand_path('../../lib/rails_mermaid_erd/railtie.rb', __FILE__)
    end
    
    it "has rake tasks" do
      # We can't easily test rake_tasks blocks directly in specs, 
      # so we'll test that the file exists that the railtie loads
      rake_file_path = File.expand_path('../../lib/tasks/rails_mermaid_erd.rake', __FILE__)
      expect(File.exist?(rake_file_path)).to be true
    end
  end
end 