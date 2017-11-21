require File.join(Rails.root, "app", "data_migrations", "move_phone_between_two_people")
# This rake task is to move phone numbers from the duplicate account to the correct account while deleting them from the duplicate account
# RAILS_ENV=production bundle exec rake migrations:move_phone_between_two_people from_hbx_id=19778757  to_hbx_id=19778757

namespace :migrations do
  desc "move phone between two people"
  MovePhoneBetweenTwoPeople.define_task :move_phone_between_two_people => :environment
end