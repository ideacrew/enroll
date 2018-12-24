# This rake task is used to deactivate SEP
# RAILS_ENV=production bundle exec rake migrations:deactivate_special_enrollment_period person_hbx_id=123123123 sep_id="12312312"
require File.join(Rails.root, "app", "data_migrations", "deactivate_special_enrollment_period")

namespace :migrations do
  desc "deactive special enrollment period"
  DeactivateSpecialEnrollmentPeriod.define_task :deactivate_special_enrollment_period => :environment
end
