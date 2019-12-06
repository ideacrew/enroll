require File.join(Rails.root, "app", "data_migrations", "correct_plan_year_end_date")
# This rake task is used to correct the end date of the benefit_application

# RAILS_ENV=production bundle exec rake migrations:correct_plan_year_end_date fein=123456789 py_effective_on=1/1/2109

namespace :migrations do
  desc "correct benefit application end date"
  CorrectPlanYearEndDate.define_task :correct_plan_year_end_date => :environment
end
