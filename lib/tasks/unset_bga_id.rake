require File.join(Rails.root, "app", "data_migrations", "unset_bga_id")
# This rake task is to unset benefit group assignment id
# RAILS_ENV=production bundle exec rake migrations:unset_bga_id hbx_id=531828
namespace :migrations do
  desc "unset benefit group assignment id"
  UnsetBgaId.define_task :unset_bga_id => :environment
end
