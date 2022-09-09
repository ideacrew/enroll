# RAILS_ENV=production bundle exec rake migrations:update_work_email_phone
# Rake task to update displayed work email, phone number, or both
# Used for Brokers and POCs that do not have a Primary Family Account
# Interactive rake that takes input from the user to be completed

require File.join(Rails.root, "app", "data_migrations","rake", "update_work_email_phone")

namespace :migrations do
  desc "Update displayed work Email and/or Phone Number"
  UpdateWorkEmailPhone.define_task :update_work_email_phone => :environment
end
