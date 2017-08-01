require File.join(Rails.root, "app", "data_migrations", "adding_employee_role")
# This rake task is to add a new adrress for broker agency
# RAILS_ENV=production bundle exec rake migrations:updating_broker_agency_address fein=999990069
namespace :migrations do
  desc "link an employee for an employer"
  UpdatingBrokerAgencyAddress.define_task :updating_broker_agency_address => :environment
end 
