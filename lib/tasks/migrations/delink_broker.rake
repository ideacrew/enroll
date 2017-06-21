require File.join(Rails.root, "app", "data_migrations", "delink_broker")
# This rake task is to delink broker
# RAILS_ENV=production bundle exec rake migrations:delink_broker person_hbx_id=19770741 legal_name=Insurance Associates fein=999994789 organization_ids_to_move =['57c78189faca1428a100399c','57c780fefaca1428a1000fbd']
namespace :migrations do
  desc "Delinking broker"
  task :delink_broker => :environment do 
    DelinkBroker.migrate()
  end
end 
