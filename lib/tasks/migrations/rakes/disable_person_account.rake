# RAILS_ENV=production bundle exec rake migrations:disable_person_account
# Rake task to disable person account and remove user account if applicable
# Interactive rake that takes input from the user to be completed

require File.join(Rails.root, "app", "data_migrations","rake", "disable_person_account")

namespace :migrations do
  desc "Terminate or Cancel HBX Enrollment"
  DisablePersonAccount.define_task :disable_person_account => :environment
end
