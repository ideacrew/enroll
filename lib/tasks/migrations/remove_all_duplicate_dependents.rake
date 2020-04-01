require File.join(Rails.root, "app", "data_migrations", "remove_all_duplicate_dependents")
# This rake task is to remove all duplicate dependents for specific use cases.
# This will treat the family member records for all hbx enrollment members on the most recent enrollment as "authority" 
# RAILS_ENV=production bundle exec rake migrations:remove_all_duplicate_dependents most_recent_active_enrollment_hbx_id=12345

namespace :migrations do
  desc "remove dependent"
  RemoveAllDuplicateDependents.define_task :remove_all_duplicate_dependents => :environment
end