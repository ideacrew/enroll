# frozen_string_literal: true

# Stores the current client configuration in config/client_config/#{state_abbreviation}/system
# RAILS_ENV=production bundle exec rake configuration:store_current_configuration
require "#{Rails.root}/lib/store_registry_config.rb"

namespace :configuration do
  desc 'Toggles Enroll Configuration between clients'
  StoreRegistryConfig.define_task :store_current_configuration => :environment
end