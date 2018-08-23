require File.join(Rails.root, "app", "data_migrations", "update_hbx_enrollment_benefit_group_assignment")
# This rake task is to add or/and remove enrollment members from/to hbx enrollment.
# It works as dialogue in the console and request to provide enrollment you want to fix and person to add/remove
# It does all the things only adding, only removing or both.
# RAILS_ENV=production bundle exec rake migrations:update_hbx_enrollment_benefit_group_assignment
namespace :migrations do
  desc "updating hbx enrollment benefit group assignment"
  UpdateHbxEnrollmentBenefitGroupAssignment.define_task :update_hbx_enrollment_benefit_group_assignment => :environment
end
