# frozen_string_literal: true

# Rake task is to update TaxHouseholdEnrollment objects for Health Enrollments with effective on or after 2022/1/1 that fall in one of the below cases:
#   1. Continuous Coverage
#   2. With more than 3 dependents which have incorrect BenchmarkPremiums
# To run rake task: bundle exec rake migrations:fix_benchmark_for_continuous_coverage_and_more_than_3_dep_enrs

# To run this on specific enrollments
# To run rake task: bundle exec rake migrations:fix_benchmark_for_continuous_coverage_and_more_than_3_dep_enrs enrollment_hbx_ids=1234, 2345

require File.join(Rails.root, 'app', 'data_migrations', 'fix_benchmark_for_continuous_coverage_and_more_than_3_dep_enrs')

namespace :migrations do
  desc 'Migrates all TaxHouseholds, TaxHouseholdMembers, and EligibilityDeterminations of Household to TaxHouseholdGroups, TaxHouseholds, and TaxHouseholdMembers'
  FixBenchmarkForContinuousCoverageAndMoreThan3DepEnrs.define_task :fix_benchmark_for_continuous_coverage_and_more_than_3_dep_enrs => :environment
end
