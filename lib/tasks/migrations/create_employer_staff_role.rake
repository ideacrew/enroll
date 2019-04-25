require File.join(Rails.root, "app", "data_migrations", "create_employer_staff_role")
# RAILS_ENV=production bundle exec rake migrations:create_employer_staff_role person_hbx_id="123456789" employer_profile_id='580e5f31082e766296006dd2'

namespace :migrations do
  desc "create_employer_staff_role"
  CreateEmployerStaffRole.define_task :create_employer_staff_role => :environment
end
