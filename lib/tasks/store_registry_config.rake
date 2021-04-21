# frozen_string_literal: true

# Stores the current client configuration in config/client_config/#{state_abbreviation}/system

require "#{Rails.root}/lib/store_registry_config.rb"

namespace :migrations do
  desc 'Toggles Enroll Configuration between clients'
  StoreRegistryConfig.define_task :store_current_configuration => :environment
end