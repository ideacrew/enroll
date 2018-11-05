require File.join(Rails.root, "app", "data_migrations", "unset_benefit_group_assignment")

# This rake task is to unset a  benefit group assignment for an census employee
# format: RAILS_ENV=production bundle exec rake migrations:unset_benefit_group_assignment ce_id=580e45abfaca142b4a001055 bga_id='597f4e7150526c21fc0000a2'

namespace :migrations do
  desc "make a benefit group assignment active for a specific census employee"
  UnsetBenefitGroupAssignment.define_task :unset_benefit_group_assignment => :environment
end