require File.join(Rails.root, "app", "data_migrations", "populate_employee_role_id_on_census_employees")

# This rake task is to populate employee role id for terminated census employee where employee role id is missing
# RAILS_ENV=production bundle exec rake migrations:populate_employee_role_id_on_census_employees fein="52-1339503"

namespace :migrations do
  desc "populating employee role id on census employees"
  PopulateEmployeeRoleIdOnCensusEmployees.define_task :populate_employee_role_id_on_census_employees => :environment
end
