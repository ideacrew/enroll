require File.join(Rails.root, "app", "data_migrations", "move_enrollment_between_two_accounts")
# This rake task is to move all hbx_enrollments between two accounts with consumer role
# RAILS_ENV=production bundle exec rake migrations:move_enrollment_between_two_accounts old_account_hbx_id=19778757  new_account_hbx_id=19778757

namespace :migrations do
  desc "move enrollment between two accounts"
  MoveEnrollmentBetweenTwoAccount.define_task :move_enrollment_between_two_accounts => :environment
end