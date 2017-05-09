require File.join(Rails.root, "app", "data_migrations", "update_broker_agency_profile")

# This rake task is to update the invalid benefit group assignments for the EE's
# format: RAILS_ENV=production bundle exec rake migrations:update_broker_agency_profile email='kallan@allegiantglobalpartners.com'
namespace :migrations do
  desc "updating invalid benefit group assignments for specific employer"
  UpdateBrokerAgencyProfile.define_task :update_broker_agency_profile => :environment
end