# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'consumer_roles', 'add_communication_preference')

# The rake task is to add communication preference for all primary people with consumer role and without communication preference.
# Command to run the rake task:
# bundle exec rake migrations:add_communication_preference
namespace :migrations do
  desc 'Adds missing communication preference for all primary people without communication preference'
  AddCommunicationPreference.define_task add_communication_preference: :environment
end
