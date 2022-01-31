# frozen_string_literal: true

require Rails.root.join('app', 'domain', 'types.rb')

EnrollRegistry = ResourceRegistry::Registry.new
client_name = ENV['CLIENT'] || 'dc'

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path  = Rails.root.join('config', 'client_config', client_name, 'system', 'config', 'templates', 'features').to_s
end

