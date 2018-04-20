require File.join(Rails.root, "app", "data_migrations", "change_hbx_id")
# Scenario:
# When a user is having an incorrect hbx_id
# This rake task is to change hbx_id 
# RAILS_ENV=production bundle exec rake migrations:change_hbx_id person_hbx_id=34323 new_hbx_id=9087879

namespace :migrations do
  desc "change hbx id"
  ChangeHbxId.define_task :change_hbx_id => :environment
end