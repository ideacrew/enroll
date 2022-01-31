# require FinancialAssistance::Engine.root.join('app', 'domain', 'types.rb')

FinancialAssistanceRegistry = ResourceRegistry::Registry.new
client_name = ENV['CLIENT'] || 'dc'

FinancialAssistanceRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = "#{Rails.root.to_s.gsub('/components/financial_assistance/spec/dummy', '')}/config/client_config/#{client_name}/system/config/templates/features"
end