# frozen_string_literal: true

# Rake task is to migrate all TaxHouseholds, TaxHouseholdMembers, and EligibilityDeterminations of Household
# to TaxHouseholdGroups, TaxHouseholds, and TaxHouseholdMembers.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:migrate_household_thhs_to_thh_group_thhs

require File.join(Rails.root, 'app', 'data_migrations', 'migrate_household_thhs_to_thh_group_thhs')

namespace :migrations do
  desc 'Migrates all TaxHouseholds, TaxHouseholdMembers, and EligibilityDeterminations of Household to TaxHouseholdGroups, TaxHouseholds, and TaxHouseholdMembers'
  MigrateHouseholdThhsToThhGroupThhs.define_task :migrate_household_thhs_to_thh_group_thhs => :environment
end
