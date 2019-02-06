require File.join(Rails.root, "app", "data_migrations", "terminate_expired_plan_year")
# This rake task used to terminate expired year, some plan years were not terminated due to invalid benefit group and end up in expired status.
# RAILS_ENV=production bundle exec rake migrations:terminate_expired_plan_year fein=477894 plan_year_start_on="01/01/2018" expected_end_on="12/01/2018" expected_termination_date="12/01/2018"
namespace :migrations do
  desc "terminate_expired_plan_year"
  TerminateExpiredPlanYear.define_task :terminate_expired_plan_year => :environment
end

