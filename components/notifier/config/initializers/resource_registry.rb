# require Notifier::Engine.root.join('app', 'domain', 'types.rb')

NotifierRegistry = ResourceRegistry::Registry.new

NotifierRegistry.configure do |config|
  config.name       = :financial_assistance
  config.created_at = DateTime.now
  config.load_path  = Notifier::Engine.root.join('system', 'config', 'templates', 'features').to_s
end