require File.join(Rails.root, "app", "data_migrations", "update_consumer_identity_verification")
# RAILS_ENV=production bundle exec rake migrations:update_consumer_identity_verification hbx_id=8531828,6899799
namespace :migrations do 
  desc "update_consumer_identity_verification"
  UpdateConsumerIdentityVerification.define_task :update_consumer_identity_verification => :environment
end