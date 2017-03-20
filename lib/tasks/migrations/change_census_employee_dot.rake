require File.join(Rails.root, "app", "data_migrations", "change_census_employee_dot")
# This rake task is to change the applied aptc amount for a given hbx_id of an hbx enrollment
# RAILS_ENV=production bundle exec rake migrations:change_census_employee_dot ssn="123456789", new_dot= Date.new(2016,1,3)
namespace :migrations do
  desc "change cenesus employee dot"
  ChangeCensusEmployeeDot.define_task :change_cenesus_employee_dot => :environment
end