require File.join(Rails.root, "app", "data_migrations", "correct_benefit_group_assignment_dates")
# This rake task is to fix the benefit group assignments which failed date guards.
namespace :migrations do
  desc "Correct benefit group assignment dates"
  CorrectBenefitGroupAssignmentDates.define_task :correct_benefit_group_assignment_dates => :environment
end
