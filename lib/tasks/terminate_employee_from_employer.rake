require File.join(Rails.root, "app", "data_migrations", "terminate_employee_from_employer")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:terminate_employee_from_employer hbx_id=0000000 emp_id="000000000"

namespace :migrations do
  desc "Terminate Employee"
  TerminateEmployeeRole.define_task :terminate_employee_from_employer => :environment
end