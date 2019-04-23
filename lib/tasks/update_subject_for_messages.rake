require File.join(Rails.root, "app", "data_migrations", "update_subject_for_messages")

# This rake task is to update the subject for the messages
# format: RAILS_ENV=production bundle exec rake migrations:update_subject_for_messages fein="009434962,009434921" incorrect_subject="old subject" correct_subject="new subject"
namespace :migrations do
  desc "updating subject for messages"
  UpdateSubjectForMessages.define_task :update_subject_for_messages => :environment
end