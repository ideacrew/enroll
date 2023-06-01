# frozen_string_literal: true

# Rake task is to populate applied_aptc for TaxHouseholdEnrollment objects for Health Enrollments with effective on or after 2022/1/1.
# To run rake task: bundle exec rake migrations:populate_applied_aptc_for_thh_enrs

# To run this on specific enrollments
# To run rake task: bundle exec rake migrations:populate_applied_aptc_for_thh_enrs enrollment_hbx_ids=1234, 2345

require File.join(Rails.root, 'app', 'data_migrations', 'populate_applied_aptc_for_thh_enrs')

namespace :migrations do
  desc 'Populated AppliedAptc and GroupEhbPremiums for TaxHouseholdEnrollments of Enrollments'
  PopulateAppliedAptcForThhEnrs.define_task :populate_applied_aptc_for_thh_enrs => :environment
end
