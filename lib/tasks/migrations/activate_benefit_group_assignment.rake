require File.join(Rails.root, "app", "data_migrations", "activate_benefit_group_assignment")
# This rake task is to activate an benefit_group_assignment for census employee or census employees 
# RAILS_ENV=production bundle exec rake migrations:activate_benefit_group_assignment action="update_benefit_group_assignment_for_ce" ce_ssn="123456789" bga_id='580e5f31082e766296006dd2'
# RAILS_ENV=production bundle exec rake migrations:activate_benefit_group_assignment action="update_benefit_group_assignment_for_er" benefit_package_id="123414141" 
namespace :migrations do
  desc "activate_benefit_group_assignment"
  ActivateBenefitGroupAssignment.define_task :activate_benefit_group_assignment => :environment
end
