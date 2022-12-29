# frozen_string_literal: true

# Rake task is to update TaxHouseholdEnrollment objects for Health Enrollments with Continuous Coverage that got created on or after 2022/1/1
# To run rake task: bundle exec rake migrations:fix_benchmark_for_continuous_coverage_enrollments

# To run this on specific enrollments
# To run rake task: bundle exec rake migrations:fix_benchmark_for_continuous_coverage_enrollments enrollment_hbx_ids=1234, 2345

require File.join(Rails.root, 'app', 'data_migrations', 'fix_benchmark_for_continuous_coverage_enrollments')

namespace :migrations do
  desc 'Migrates all TaxHouseholds, TaxHouseholdMembers, and EligibilityDeterminations of Household to TaxHouseholdGroups, TaxHouseholds, and TaxHouseholdMembers'
  FixBenchmarkForContinuousCoverageEnrollments.define_task :fix_benchmark_for_continuous_coverage_enrollments => :environment
end
