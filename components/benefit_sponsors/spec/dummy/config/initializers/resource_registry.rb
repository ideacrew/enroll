EnrollRegistry = ResourceRegistry::Registry.new

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = Rails.root.to_s.gsub("/components/benefit_sponsors/spec/dummy", "") + "/system/config/templates/features"
end