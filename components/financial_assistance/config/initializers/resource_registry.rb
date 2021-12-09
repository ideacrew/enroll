# require FinancialAssistance::Engine.root.join('app', 'domain', 'types.rb')

FinancialAssistanceRegistry = ResourceRegistry::Registry.new

FinancialAssistanceRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = "#{Rails.root.to_s.gsub('/components/financial_assistance/spec/dummy', '')}/system/config/templates/features"
end