require File.join(Rails.root, "app", "data_migrations", "add_and_remove_coverage_household_member")
# This rake task is to add and remove coverage household member records
# RAILS_ENV=production bundle exec rake migrations:add_and_remove_coverage_household_member primary_hbx_id="34344" action="add_chm" family_member_ids="5a4e897713c8d6ca940000a5,"

# RAILS_ENV=production bundle exec rake migrations:add_and_remove_coverage_household_member primary_hbx_id="34344" action="remove_chm" family_member_ids="5a4e897713c8d6ca940000a5,"

namespace :migrations do
  desc "add/remove coverage household member"
  AddAndRemoveCoverageHouseholdMember.define_task :add_and_remove_coverage_household_member => :environment
end 
