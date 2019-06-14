require File.join(Rails.root, "app", "data_migrations", "change_hbx_id")
# Scenario:
# When a person or organization needs to update hbx_id 

# This rake task is to change a person's hbx_id to a specific hbx_id 
# RAILS_ENV=production bundle exec rake migrations:change_hbx_id hbx_id=34323 new_hbx_id=9087879 action="change_person_hbx"
# to change the  person's hbx_id to a new random one
# RAILS_ENV=production bundle exec rake migrations:change_hbx_id hbx_id=34323 new_hbx_id="" action="change_person_hbx"

# This rake task is to change an organization's hbx_id to a specific hbx_id 
# RAILS_ENV=production bundle exec rake migrations:change_hbx_id hbx_id=34323 new_hbx_id=9087879 action="change_organization_hbx"
# to change an organization's hbx_id to a new random one
# RAILS_ENV=production bundle exec rake migrations:change_hbx_id hbx_id=34323 new_hbx_id="" action="change_organization_hbx"


namespace :migrations do
  desc "change hbx id"
  ChangeHbxId.define_task :change_hbx_id => :environment
end