require File.join(Rails.root, "app", "data_migrations", "move_due_date_to_verification_type_level")
# This rake task is to move due date to verification type level
# RAILS_ENV=production bundle exec rake migrations:move_due_date_to_verification_type_level
namespace :migrations do
  desc "move_due_date_to_verification_type_level"
  MoveDueDateToVerificationTypeLevel.define_task :move_due_date_to_verification_type_level => :environment
end
