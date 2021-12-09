NotifierRegistry = ResourceRegistry::Registry.new

NotifierRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = "#{Rails.root.to_s.gsub('/components/notifier/spec/dummy', '')}/system/config/templates/features"
end