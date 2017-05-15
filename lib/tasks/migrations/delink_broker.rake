require File.join(Rails.root, "app", "data_migrations", "delink_broker")
# This rake task is to delink broker
# RAILS_ENV=production bundle exec rake migrations:delink_broker person_hbx_id=19770741 legal_name=Insurance Associates
namespace :migrations do
  desc "Delinking broker"
  task :delink_broker => :environment do 
    DelinkBroker.migrate()
  end
end 
