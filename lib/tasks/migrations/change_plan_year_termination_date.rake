require File.join(Rails.root, "app", "data_migrations", "change_plan_year_termination_date")
# This rake task is to change the termination date of an already terminated plan year. It won't change any related enrollment's end date 
# RAILS_ENV=production bundle exec rake migrations:change_plan_year_termination_date fein=123123123 plan_year_start_on=11/23/2015 new_terminated_on=12/31/2015 
namespace :migrations do
  desc "Changing termination date of a terminated plan year "
  ChangePlanYearTerminationDate.define_task :change_plan_year_termination_date => :environment
end 