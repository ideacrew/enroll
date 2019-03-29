require File.join(Rails.root, "app", "data_migrations", "activate_employee_renewal_benefit_group_assignments")

# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:activate_employee_renewal_benefit_group_assignments feins="123456789" effective_on="01/01/2019"
namespace :migrations do
  desc "Activate employee renewal benefit group assignments"

  ActivateEmployeeRenewalBenefitGroupAssignments.define_task :activate_employee_renewal_benefit_group_assignments => :environment
end