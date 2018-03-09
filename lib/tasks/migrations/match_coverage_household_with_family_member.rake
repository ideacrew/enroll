require File.join(Rails.root, "app", "data_migrations", "remove_coverage_household_member")
# RAILS_ENV=production bundle exec rake migrations:match_coverage_household_with_family_member person_hbx_id=19810927
namespace :migrations do
  desc "remove coverage household family member from coverage household"
  MatchCoverageHouseholdWithFamilyMember.define_task :remove_coverage_household_member => :environment
end