require File.join(Rails.root, "app", "data_migrations", "cobra_renewal_enrollments_premium")
# This rake task is to update enrollment member
# RAILS_ENV=production bundle exec rake migrations:cobra_renewal_enrollments_premium person_hbx_id=19795166 enrollment_hbx_id=770626
namespace :migrations do
  desc "Changing cobra renewal enrollments premium"
  CobraRenewalEnrollmentsPremium.define_task :cobra_renewal_enrollments_premium => :environment
end