require File.join(Rails.root, "app", "data_migrations", "update_benefit_group_assignment_details")
# This rake task is to change the attributes on benefit group assignment
# RAILS_ENV=production bundle exec rake migrations:update_benefit_group_assignment_details ce_id=123abc bga_id=123456 new_state="coverage_expired" action="change_aasm_state"
namespace :migrations do
  desc "changing attributes on benefit group assignment"
  UpdateBenefitGroupAssignmentDetails.define_task :update_benefit_group_assignment_details => :environment
end
