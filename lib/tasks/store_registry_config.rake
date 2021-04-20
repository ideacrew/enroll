# frozen_string_literal: true

# Stores the current client configuration in config/client_config/#{state_abbreviation}/system
# If there is a current client configuration there, it will store that configuration first in
# config/client_config/#{state_abbreviation}/todays_date_config# For Ex: RAILS_ENV=production bundle exec rake migrations:store_current_configuration

require "#{Rails.root}/lib/store_registry_config.rb"

namespace :migrations do
  desc 'Toggles Enroll Configuration between clients'
  StoreRegistryConfig.define_task :store_current_configuration => :environment
end