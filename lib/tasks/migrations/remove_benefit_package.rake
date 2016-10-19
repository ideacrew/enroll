require File.join(Rails.root, "app", "data_migrations", "remove_benefit_package")
# This rake task is to change the ER's contributions
# RAILS_ENV=production bundle exec rake migrations:remove_benefit_package fein=264793467 aasm_state=renewing_enrolling title=test2
# if you are using this rake task to delete the benefit group, also make sure the census employees has access to their accounts, if not chech
# bundle exec rake migrations:remove_invalid_benefit_group_assignments fein=264793467 task
namespace :migrations do
  desc "removing benefit group"
  RemoveBenefitPackage.define_task :remove_benefit_package => :environment
end 
