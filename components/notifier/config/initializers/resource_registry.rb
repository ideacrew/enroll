# frozen_string_literal: true

NotifierRegistry = ResourceRegistry::Registry.new
client_name = ENV['CLIENT'] || 'dc'

NotifierRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = "#{Rails.root.to_s.gsub('/components/notifier/spec/dummy', '')}/config/client_config/#{client_name}/system/config/templates/features"
end
