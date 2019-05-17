require File.join(Rails.root, "app", "data_migrations", "employee_dependent_age_off_termination_notice")
# This rake task is to send dependent age off termination notice to employees both congressional and non-congressional
# RAILS_ENV=production bundle exec rake migrations:employee_dependent_age_off_termination_notice hbx_ids='hbx_id_1 hbx_id_2'
namespace :migrations do
  desc "Rake task that sends out dependent age off termination notifications to congressional and non congressional employees"
  EmployeeDependentAgeOffTerminationNotice.define_task :employee_dependent_age_off_termination_notice => :environment
end