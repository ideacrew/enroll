require File.join(Rails.root, "app", "data_migrations", "delink_broker")
# This rake task is to delink broker
# RAILS_ENV=production bundle exec rake migrations:delink_broker person_hbx_id=19770741 legal_name=Insurance Associates fein=999994789
# RAILS_ENV=production bundle exec rake migrations:delink_broker person_hbx_id=cc369ef2b2b24296adbc23800505d75b legal_name : Financial Benefit Services LLC fein=999900000 organization_ids_to_move =['58c063ebf1244e21cb000b44','586e80bbfaca14110f0003f8’,’5638b90369702d6c416d0000']
namespace :migrations do
  desc "Delinking broker"
  task :delink_broker => :environment do 
    DelinkBroker.migrate()
  end
end 
