# frozen_string_literal: true

NotifierRegistry = ResourceRegistry::Registry.new

NotifierRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = "#{Rails.root.to_s.gsub('/components/notifier/', '')}/system/config/templates/features"
end