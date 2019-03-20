require File.join(Rails.root, "app", "data_migrations", "update_verification_type_status")
# The task to run is RAILS_ENV=production bundle exec rake migrations:update_verification_type_status hbx_id="121111" verification_type_name="Type Name"

namespace :migrations do
  desc 'Update citizen status for people who are fully verified but not lawfully present'
  desc 'Update verification type status'
  UpdateVerificationTypeStatus.define_task update_verification_type_status: :environment
end
