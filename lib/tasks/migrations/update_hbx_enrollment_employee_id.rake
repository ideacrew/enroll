require File.join(Rails.root, "app", "data_migrations", "update_hbx_enrollment_employee_role_id")

# RAILS_ENV=production bundle exec rake migrations:update_hbx_enrollment_employee_role_id enrollment_hbx_id='6587656' employee_role_id='5af3354a50526c1b3400002d' 

namespace :migrations do
  desc "updating hbx enrollment employee role id"
  UpdateHbxEnrollmentEmployeeRoleId.define_task :update_hbx_enrollment_employee_role_id => :environment
end
