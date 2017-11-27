# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:delink_employee_role correct_person_hbx_id="123123"

require File.join(Rails.root, "app", "data_migrations", "delink_employee_role")
namespace :migrations do
  desc "delink_employee_role"
  DelinkEmployeeRole.define_task :delink_employee_role => :environment
end
