require File.join(Rails.root, "app", "data_migrations", "remove_policy")
# This rake task is to cancel hbx enrollmet
# RAILS_ENV=production bundle exec rake migrations:remove_policy hbx_id=531828 
namespace :migrations do
  desc "changing effectve on date for enrollment"
  RemovePolicy.define_task :remove_policy => :environment
end 
