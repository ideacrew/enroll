require File.join(Rails.root, "app", "data_migrations", "cobra_renewal_enrollments_premium")
# This rake task is to update enrollment member
# RAILS_ENV=production bundle exec rake migrations:cobra_renewal_enrollments_premium hbx_id=19795166 hbx_id=
namespace :migrations do
  desc "Changing cobra renewal enrollments premium"
  CobraRenewalEnrollmentsPremium.define_task :cobra_renewal_enrollments_premium => :environment
end