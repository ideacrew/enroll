# frozen_string_literal: true

EnrollRegistry = ResourceRegistry::Registry.new

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = "#{Rails.root.to_s.gsub('/components/financial_assistance/spec/dummy', '')}/system/config/templates/features"
end