require File.join(Rails.root, "app", "data_migrations", "add_and_remove_coverage_household_member")
# This rake task is to add and remove coverage household member records

# TO Add Coverage Household Members
# RAILS_ENV=production bundle exec rake migrations:add_and_remove_coverage_household_member primary_hbx_id="34344" action="add_chm" family_member_ids="5a4e897713c8d6ca940000a5"

# TO Remove Coverage Household Member for existing family member
# RAILS_ENV=production bundle exec rake migrations:add_and_remove_coverage_household_member primary_hbx_id="34344" action="remove_chm" family_member_ids="5a4e897713c8d6ca940000a5"

# TO Remove Coverage Household Member for non-existing family member
# RAILS_ENV=production bundle exec rake migrations:add_and_remove_coverage_household_member primary_hbx_id="34344" family_member_ids="5a4e897713c8d6ca940000a5", "5a4e897713c8d6ca940000a5" invalid_family_members="true"


namespace :migrations do
  desc "add/remove coverage household member"
  AddAndRemoveCoverageHouseholdMember.define_task :add_and_remove_coverage_household_member => :environment
end 
