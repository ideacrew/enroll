require File.join(Rails.root, "app", "data_migrations", "deactivate_benefit_group_assignment")
# This rake task is to deactivate a benefit_group_assignment of a census employee
# RAILS_ENV=production bundle exec rake migrations:deactivate_benefit_group_assignment ce_ssn="123456789" bga_id='580e5f31082e766296006dd2'
namespace :migrations do
  desc "deactivate_benefit_group_assignment"
  DeactivateBenefitGroupAssignment.define_task :deactivate_benefit_group_assignment => :environment
end
