require File.join(Rails.root, "app", "data_migrations", "add_plan_to_enrollment")
# This rake task is to add a plan to an enrollment when the plan is missing
# RAILS_ENV=production bundle exec rake migrations:add_plan_to_enrollment enrollment_id=561e789769702d5617a00000 plan_id=57febed8faca1426d8004c5b
namespace :migrations do
  desc "add a plan to Enrollment"
  AddPlantoEnrollment.define_task :add_plan_to_enrollment => :environment
end 