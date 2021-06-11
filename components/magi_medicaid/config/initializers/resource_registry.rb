# frozen_string_literal: true

# require FinancialAssistance::Engine.root.join('app', 'domain', 'types.rb')

MagiMedicaidRegistry = ResourceRegistry::Registry.new

MagiMedicaidRegistry.configure do |config|
  config.name       = :magi_medicaid
  config.created_at = DateTime.now
  config.load_path  = MagiMedicaid::Engine.root.join('system', 'features').to_s
end