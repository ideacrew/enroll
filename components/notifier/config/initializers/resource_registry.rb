# frozen_string_literal: true

NotifierRegistry = ResourceRegistry::Registry.new
client_name_file = if File.exist?("#{Rails.root.to_s.gsub('/components/benefit_sponsors/spec/dummy', '')}/current_configuration.txt")
                     File.read("#{Rails.root.to_s.gsub('/components/benefit_sponsors/spec/dummy', '')}/current_configuration.txt")
                   else
                     File.read("#{Rails.root.to_s.gsub('/components/notifier/spec/dummy', '')}/current_configuration.txt")
                   end

NotifierRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = "#{Rails.root.to_s.gsub('/components/notifier/spec/dummy', '')}/config/client_config/#{client_name_file}/system/config/templates/features"
end
