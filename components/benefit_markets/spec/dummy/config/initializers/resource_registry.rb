# frozen_string_literal: true

EnrollRegistry = ResourceRegistry::Registry.new
client_name = ENV['CLIENT'] || 'dc'

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path  = Rails.root.to_s.gsub("/components/benefit_markets/spec/dummy", "") + "/config/client_config/#{client_name}/system/config/templates/features"
end