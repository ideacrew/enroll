require File.join(Rails.root, "app", "data_migrations", "employer_staff_role_aasm_fix")

# RAILS_ENV=production bundle exec rake migrations:employer_staff_role_aasm_fix

namespace :migrations do
  desc "Some employer_staff_roles do not have the aasm_state field. This will fix the issue."
  EmployerStaffRoleAasmFix.define_task :employer_staff_role_aasm_fix => :environment
end