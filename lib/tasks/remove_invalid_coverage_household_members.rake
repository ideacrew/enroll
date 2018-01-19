require File.join(Rails.root, "app", "data_migrations", "remove_invalid_coverage_household_members")
# RAILS_ENV=production bundle exec rake migrations:remove_invalid_coverage_household_members person_hbx_id=19810927

namespace :migrations do
  desc "Remove invalid coverage household members"
  RemoveInvalidCoverageHouseholdMembers.define_task :remove_invalid_coverage_household_members => :environment
end