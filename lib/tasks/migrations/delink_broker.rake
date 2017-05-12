require File.join(Rails.root, "app", "data_migrations", "delink_broker")
# This rake task is to add employee role
# RAILS_ENV=production bundle exec rake migrations:adding_employee_role census_employee_id=5835bff6082e7645b70000de person_id=53e69677eb899ad9ca02cbfd
namespace :migrations do
  desc "Delinking broker"
  DelinkBroker.define_task :delink_broker_agency_profile_id => :environment
end 
