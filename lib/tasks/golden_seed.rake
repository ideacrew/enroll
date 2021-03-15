# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "golden_seed_update_benefit_application_dates")
require File.join(Rails.root, "app", "data_migrations", "golden_seed_shop")

# components/benefit_markets/app/models/benefit_markets/forms/product_form.rb
# golden_seed_update_benefit_application_dates
# This rake task should be used in conjunction with the database seed with employers for testing
# Rake takes EITHER default employer list from seed (provide no value for target_employer_name_list)
# OR a list of legal names
# and takes coverage_start_on and end_on dates to form effective period
# RAILS_ENV=production bundle exec rake migrations:golden_seed_update_benefit_application_dates coverage_start_on="01/01/2020" coverage_end_on="05/01/2020" target_employer_name_list="Pizza Planet, Fake Corporation1"

# golden_seed_shop
# This rake task generates employers (complete), employees (TODO), and dependents (TODO) for specific,
# pre existing plans (TODO) and carriers (TODO).
# and takes coverage_start_on and end_on dates to form effective period
# will use default coverage_start_on and coverage_end_on unless they are passed through
# as arguement here: coverage_start_on="1/1/2020" coverage_end_on="1/1/2021"
# RAILS_ENV=production bundle exec rake migrations:golden_seed_shop
# For IVL
# RAILS_ENV=production bundle exec rake migrations:golden_seed_individual

namespace :migrations do
  desc "Generates consumers, families, and enrollments for them from existing carriers and plans. Can be run on any environment without affecting existing data. Uses existing carriers/plans."
  GoldenSeedSHOP.define_task :golden_seed_individual => :environment
  desc "Generates Employers, Employees, and Dependents from existing carriers and plans. Can be run on any environment without affecting existing data. Uses existing carriers/plans."
  GoldenSeedSHOP.define_task :golden_seed_shop => :environment

  desc "Updates effective on periods for employer benefit applications from employer list a specific dump. Can be enhanced to ingest employer legal name list."
  GoldenSeedUpdateBenefitApplicationDates.define_task :golden_seed_update_benefit_application_dates => :environment
end