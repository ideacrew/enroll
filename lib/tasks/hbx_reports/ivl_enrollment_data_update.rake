require File.join(Rails.root, "app", "data_migrations", "ivl_enrollment_data_update")

namespace :migrations do
  desc "Correct the ivl enrollment"
  IvlEnrollmentDataUpdate.define_task :ivl_enrollment_data_update => :environment
end