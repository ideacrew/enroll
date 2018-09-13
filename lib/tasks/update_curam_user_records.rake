require File.join(Rails.root, "app", "data_migrations", "update_curam_user_records")
# ******Imp Note: Should be used ONLY when confirmed that an user in IAM is already been removed / needs an update after the approval. ******
# RAILS_ENV=production bundle exec rake migrations:update_curam_user_records find_user_by="email" user_email="present_email" new_user_name="required_username" action="update_username"
# RAILS_ENV=production bundle exec rake migrations:update_curam_user_records find_user_by="user_name" new_user_email="example@gmail.com" user_name="valid_username" action="update_email"
# RAILS_ENV=production bundle exec rake migrations:update_curam_user_records find_user_by="user_name" new_dob=31/12/2019 user_name="valid_username" action="update_dob"
# RAILS_ENV=production bundle exec rake migrations:update_curam_user_records find_user_by="user_name" new_ssn="261737283" user_name="valid_username" action="update_ssn"
namespace :migrations do
  desc "destroying headless user records & updating user name, oim id on user & also updating email on person"
  UpdateCuramUserRecords.define_task :update_curam_user_records => :environment
end 
