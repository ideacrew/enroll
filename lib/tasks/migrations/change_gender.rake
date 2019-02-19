# Rake task to change Gender of an person with employee role
# RAILS_ENV=production bundle exec rake migrations:change_gender ce_id="5640343869702d1adf002500" hbx_id="19748191" gender="female"
#Rake task to change Gender of an person without employee roles
# RAILS_ENV=production bundle exec rake migrations:change_gender ce_id="" hbx_id="19748191" gender="female"

require File.join(Rails.root, "app", "data_migrations", "change_gender")
namespace :migrations do
  desc "Changing Gender for a person record"
  ChangeGender.define_task :change_gender => :environment
end
