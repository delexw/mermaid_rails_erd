# frozen_string_literal: true

require "rails_mermaid_erd"

namespace :rails_mermaid_erd do
  desc "Generate Mermaid ERD diagram from ActiveRecord models"
  task generate: :environment do
    output_path = Rails.root.join("tmp", "#{ActiveRecord::Base.connection.current_database}.mmd")

    # Ensure tmp directory exists
    FileUtils.mkdir_p(File.dirname(output_path))

    if File.exist?(output_path)
      puts "Warning: Overwriting existing file at #{output_path}"
      # Optional: Create backup
      # FileUtils.cp(output_path, "#{output_path}.bak")
    end

    begin
      File.open(output_path, "w") do |file|
        puts "Generating Mermaid ERD diagram..."
        RailsMermaidErd.generate(output: file)
      end
    rescue Errno::EACCES, IOError => e
      puts "Error: Could not write to #{output_path}: #{e.message}"
    end

    # Make output instructions more visible
    puts "\n#{'=' * 80}"
    puts "\n ERD diagram generated at: #{output_path}"
    puts "\n  📊 DIAGRAM VIEWING:\n".upcase
    puts "\n   - Mermaid ERD Visualizer: https://github.com/delexw/mermaid-erd-visualizer"
    puts "\n"
    puts "#{'=' * 80}\n"
  end
end
