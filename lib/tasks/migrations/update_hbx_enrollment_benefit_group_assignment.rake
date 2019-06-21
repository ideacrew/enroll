require File.join(Rails.root, "app", "data_migrations", "update_hbx_enrollment_benefit_group_assignment")

# RAILS_ENV=production bundle exec rake migrations:update_hbx_enrollment_benefit_group_assignment hbx_id='6587656' benefit_group_assignment_id='5af3354a50526c1b3400002d' 
# hbx_id='6587656' ( hbx_enrollment_id)
namespace :migrations do
  desc "updating hbx enrollment benefit group assignment"
  UpdateHbxEnrollmentBenefitGroupAssignment.define_task :update_hbx_enrollment_benefit_group_assignment => :environment
end
