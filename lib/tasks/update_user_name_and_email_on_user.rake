require File.join(Rails.root, "app", "data_migrations", "update_user_name_and_email_on_user")
# This rake task is to update the email and username on User record
# RAILS_ENV=production bundle exec rake migrations:update_user_name_and_email_on_user
namespace :migrations do
  desc "destroying headless user records & updating user name, oim id on user"
  UpdateUserNameAndEmailOnUser.define_task :update_user_name_and_email_on_user => :environment
end 
