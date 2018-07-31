require File.join(Rails.root, "app", "data_migrations", "remove_coverage_household_member")
# RAILS_ENV=production bundle exec rake migrations:remove_coverage_household_member person_hbx_id=19810927 family_member_id=123123123 coverage_household_member_id=8765467 action=remove_invalid_fm
#The below rake removes the dup chm's with no family record from coverage household.
# RAILS_ENV=production bundle exec rake migrations:remove_invaild_coverage_household_member person_hbx_id=19892737 action=remove_invalid_chms
namespace :migrations do
  desc "removefamily member from coverage household"
  RemoveCoverageHouseholdMember.define_task :remove_coverage_household_member => :environment
end