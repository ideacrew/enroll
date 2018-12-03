require File.join(Rails.root, "app", "data_migrations", "update_employee_role_id")
# This rake task is to move hbx_enrollment between two accounts
# For Updating Employee Role id on Enrollments
# RAILS_ENV=production bundle exec rake migrations:update_employee_role_id hbx_id="23231414" action="update_employee_role_id_to_enrollment"
# For Updating Employee Role id on Census Employee Record 
# RAILS_ENV=production bundle exec rake migrations:update_employee_role_id hbx_id="23231414" action="update_employee_role_id_to_ce" 
namespace :migrations do
  desc "move enrollment between two accounts"
  UpdateEmployeeRoleId.define_task :update_employee_role_id => :environment
end