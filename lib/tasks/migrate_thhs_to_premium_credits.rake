# frozen_string_literal: true

# Rake task is to migrate all TaxHouseholds, TaxHouseholdMembers, and EligibilityDeterminations to
# GroupPremiumCredits, and MemberPremiumCredits.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:migrate_thhs_to_premium_credits

require File.join(Rails.root, 'app', 'data_migrations', 'migrate_thhs_to_premium_credits')

namespace :migrations do
  desc 'Migrates Tax Households to Premium Credits'
  MigrateThhsToPremiumCredits.define_task :migrate_thhs_to_premium_credits => :environment
end
