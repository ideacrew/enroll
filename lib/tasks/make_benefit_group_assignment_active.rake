require File.join(Rails.root, "app", "data_migrations", "make_benefit_group_assignment_active")

# This rake task is to make a benefit group assignments active for census employee
# format: RAILS_ENV=production bundle exec rake migrations:make_benefit_group_assignment_active ce_id=580e45abfaca142b4a001055

namespace :migrations do
  desc "make a benefit group assignment active for a specific census employee"
  MakeBenefitGroupAssignmentActive.define_task :make_benefit_group_assignment_active => :environment
end