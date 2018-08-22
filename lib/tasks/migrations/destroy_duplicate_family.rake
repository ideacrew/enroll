require File.join(Rails.root, "app", "data_migrations", "destroy_duplicate_family")
# RAILS_ENV=production bundle exec rake migrations:destroy_duplicate_family family_id=""
namespace :migrations do
  desc "deactivate_duplicate_family"
  DestroyDuplicateFamily.define_task :destroy_duplicate_family => :environment
end
