require File.join(Rails.root, "app", "data_migrations", "remove_coverage_household_member_for_inactive_family_member")
# RAILS_ENV=production bundle exec rake migrations:remove_coverage_household_member_for_inactive_family_member person_hbx_id=19810927
namespace :migrations do
  desc "remove_coverage_household_member_for_inactive_family_member"
  RemoveCoverageHouseHoldMemberForInactiveFamilyMember.define_task :remove_coverage_household_member_for_inactive_family_member => :environment
end