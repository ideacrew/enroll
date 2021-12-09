# frozen_string_literal: true

require Rails.root.join('app', 'domain', 'types.rb')

EnrollRegistry = ResourceRegistry::Registry.new
client_name_file = File.read("#{Rails.root}/current_configuration.txt")

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path  = Rails.root.join('config', 'client_config', client_name_file, 'system', 'config', 'templates', 'features').to_s
end

