require File.join(Rails.root, "app", "data_migrations", "update_super_group")
# This rake task is to update super groups id of a plan/product
# RAILS_ENV=production bundle exec rake migrations:update_super_group active_year="2017" hios_id="41304MA0041055-01" super_group_id="NHPHMOMM55-86DV"

namespace :migrations do
  desc "update_super_group"
  UpdateSuperGroup.define_task :update_super_group => :environment
end