require File.join(Rails.root, "app", "data_migrations", "fix_plan_years_to_obey_minimum_open_enrollment_period")
# This rake task is to change the effective on kind from "date-of hire" to "first_of_month" for benefit group
# RAILS_ENV=production bundle exec rake migrations:change_new_hire_rule fein=451173603
namespace :migrations do
  desc "fix plan year to have valid open enrollment period of minnimum 5 days."
  FixPlanYearsToObeyMinimumOpenEnrollmentPeriod.define_task :fix_plan_years_to_obey_minimum_open_enrollment_period => :environment
end