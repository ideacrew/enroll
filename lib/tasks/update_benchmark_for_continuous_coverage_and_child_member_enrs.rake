# frozen_string_literal: true

# Rake task is to update TaxHouseholdEnrollment objects for Health Enrollments with effective on or after 2022/1/1 that fall in one of the below cases:
#   1. Continuous Coverage
#   2. Children aged 20 or below. This is to fix the incorrectly calculated second lowest cost standalone dental plan ehb premium
# To run rake task: bundle exec rake migrations:update_benchmark_for_continuous_coverage_and_child_member_enrs

# To run this on specific enrollments
# To run rake task: bundle exec rake migrations:update_benchmark_for_continuous_coverage_and_child_member_enrs enrollment_hbx_ids=1234, 2345

require File.join(Rails.root, 'app', 'data_migrations', 'update_benchmark_for_continuous_coverage_and_child_member_enrs')

namespace :migrations do
  desc 'Updates TaxHouseholdEnrollments with correct Benchmark Values'
  UpdateBenchmarkForContinuousCoverageAndChildMemberEnrs.define_task :update_benchmark_for_continuous_coverage_and_child_member_enrs => :environment
end
