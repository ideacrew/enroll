require File.join(Rails.root, "app", "data_migrations", "fix_invalid_benefit_group_assignments")

# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:fix_invalid_benefit_group_assignments
namespace :migrations do
  desc "Job to fix invalid benefit group assignments under employees"

  FixInvalidBenefitGroupAssignments.define_task :fix_invalid_benefit_group_assignments => :environment
end