require File.join(Rails.root, "app", "data_migrations", "update_employer_profile_id_for_employee")
# This rake task is to update employee_role's benefit_sponsors_employer_profile_id
# RAILS_ENV=production bundle exec rake migrations:update_employer_profile_id_for_employee organization_fein="1234567" employee_role_id="hs7367vjhds73265"

namespace :migrations do
  desc "update_employer_profile_id_for_employee"
  UpdateEmployerProfileIdForEmployee.define_task :update_employer_profile_id_for_employee => :environment
end
