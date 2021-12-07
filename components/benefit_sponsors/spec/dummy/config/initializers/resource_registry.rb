# frozen_string_literal: true

EnrollRegistry = ResourceRegistry::Registry.new
client_name_file = File.read("#{Rails.root.to_s.gsub('/components/benefit_sponsors/spec/dummy', '')}/current_configuration.txt")


EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = "#{Rails.root.to_s.gsub('/components/benefit_sponsors/spec/dummy', '')}/config/client_config/#{client_name_file}/system/config/templates/features"
end