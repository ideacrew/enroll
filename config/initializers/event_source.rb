EventSource.configure do |config|
  config.application = :enroll
  config.adapter = :resque_bus
  config.root    = Rails.root.join('app', 'event_source')
  config.logger  = Rails.root.join('log', 'event_source.log')
end
