require File.join(Rails.root, "app", "data_migrations", "update_fields_of_employee_role")
# This is a multipurpose rake task is 
# To update employee_role's benefit_sponsors_employer_profile_id field
# RAILS_ENV=production bundle exec rake migrations:update_fields_of_employee_role organization_fein="1234567" employee_role_id="hs7367vjhds73265" action="update_benefit_sponsors_employer_profile_id"
# To update employee_role's update_census_employee_id field
# RAILS_ENV=production bundle exec rake migrations:update_fields_of_employee_role organization_fein="1234567" employee_role_id="hs7367vjhds73265" action="update_census_employee_id"
# To update_census_employee_id_using_employee_role
# RAILS_ENV=production bundle exec rake migrations:update_fields_of_employee_role census_employee_id="1234567" employee_role_id="hs7367vjhds73265" action="update_with_given_census_employee_id"

namespace :migrations do
  desc "update_fields_of_employee_role"
  UpdateFieldsOfEmployeeRole.define_task :update_fields_of_employee_role => :environment
end