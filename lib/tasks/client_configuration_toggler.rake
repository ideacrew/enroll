# frozen_string_literal: true

# This will switch the current rails configuration to a different state for another client. Pass the state abbreviation as an arguement
# For Ex: RAILS_ENV=production bundle exec rake configuration:client_configuration_toggler client='me'

require "#{Rails.root}/lib/client_configuration_toggler.rb"

namespace :configuration do
  desc 'Toggles Enroll Configuration between clients'
  ClientConfigurationToggler.define_task :client_configuration_toggler => :environment
end
