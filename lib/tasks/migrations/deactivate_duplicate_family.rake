require File.join(Rails.root, "app", "data_migrations", "deactivate_duplicate_family")
# RAILS_ENV=production bundle exec rake migrations:deactivate_duplicate_family hbx_id=""
namespace :migrations do
  desc "deactivate_duplicate_family"
  DeactivateDuplicateFamily.define_task :deactivate_duplicate_family => :environment
end
