require File.join(Rails.root, "app", "data_migrations", "remove_family_member_from_coverage_household")
# RAILS_ENV=production bundle exec rake migrations:remove_family_member_from_coverage_household person_hbx_id=19810927 action=RemoveCoverageHouseholdMember family_member_id=123123123
# # RAILS_ENV=production bundle exec rake migrations:remove_family_member_from_coverage_household person_hbx_id=8767567 action=RemoveDuplicateMembers person_first_name=Gavin,G person_last_name=vozar
namespace :migrations do
  desc "remove_family member from coverage household"
  RemoveFamilyMemberFromCoverageHousehold.define_task :remove_family_member_from_coverage_household => :environment
end