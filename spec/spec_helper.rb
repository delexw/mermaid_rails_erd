# frozen_string_literal: true

require "rails_mermaid_erd"

# Stub out ActiveRecord for tests
if !Object.const_defined?(:ActiveRecord) || !defined?(ActiveRecord::Base)
  module ActiveRecord
    class Base
      def self.descendants
        []
      end

      def self.<(_other)
        false
      end

      def self.abstract_class?
        true
      end

      def self.table_exists?
        true
      end

      def self.base_class
        self
      end

      def self.connection
        nil
      end
    end

    module Associations
      class CollectionProxy
      end
    end

    class Migration
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
