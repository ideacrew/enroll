require File.join(Rails.root, "app", "data_migrations", "update_broker_agency_profile_id")

# This rake task is to update the broker agency profile id for Users
# format: RAILS_ENV=production bundle exec rake migrations:update_broker_agency_profile_id email='kallan@allegiantglobalpartners.com'
namespace :migrations do
  desc "updating broker agency profile id for specific user"
  UpdateBrokerAgencyProfileId.define_task :update_broker_agency_profile => :environment
end