require File.join(Rails.root, "app", "data_migrations", "adding_employee_role")
# This rake task is to add employee role
# RAILS_ENV=production bundle exec rake migrations:adding_employee_role census_employee_id=5808f3a113c8d609b00000c8 person_id=5808d14413c8d609b000008b
namespace :migrations do
  desc "link an employee for an employer"
  AddingEmployeeRole.define_task :adding_employee_role => :environment
end 
