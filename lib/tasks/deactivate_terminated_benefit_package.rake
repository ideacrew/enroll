require File.join(Rails.root, "app", "data_migrations", "deactivate_terminated_benefit_package")
# This rake task is to deactivate the terminated benefit package for all the employee's in the employer roster
namespace :migrations do
  desc "deactivating terminated benefit package for the employee roster"
  DeactivateTerminatedBenefitPackage.define_task :deactivate_terminated_benefit_package => :environment
end
