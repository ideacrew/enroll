require File.join(Rails.root, "app", "data_migrations", "update_open_enrollment_dates_for_bcp")
# This rake task is to change the open enrollment end on date
# RAILS_ENV=production bundle exec rake migrations:update_open_enrollment_dates_for_bcp title="Individual Market Benefits 2018" new_oe_start_date="11/13/2017" new_oe_end_date="12/11/2017"
namespace :migrations do
  desc "updating open enrollment dates for benefit coverage period"
  UpdateOpenEnrollmentDatesForBcp.define_task :update_open_enrollment_dates_for_bcp => :environment
end
