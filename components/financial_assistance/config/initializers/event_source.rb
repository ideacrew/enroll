EventSource.configure do |config|
  config.application = :financial_assistance
  config.adapter = :resque_bus
  config.root    = FinancialAssistance::Engine.root.join('app', 'event_source', 'financial_assistance')
  config.logger  = Rails.root.join('log', 'event_source.log')
end