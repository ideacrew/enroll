require File.join(Rails.root, "app", "data_migrations", "add_missing_coverage_household_member")
# This rake task adds missing coverage household members
# RAILS_ENV=production bundle exec rake migrations:add_missing_coverage_household_member hbx_id=876546 relation=spouse
namespace :migrations do
  desc "add_missing_coverage_household_member"
  AddMissingCoverageHouseholdMember.define_task :add_missing_coverage_household_member => :environment
end
