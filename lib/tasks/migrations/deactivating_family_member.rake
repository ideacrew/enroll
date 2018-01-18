require File.join(Rails.root, "app", "data_migrations", "deactivating_family_member")
# This rake task is to deactivate a family member
# RAILS_ENV=production bundle exec rake migrations:deactivating_family_member family_member_id=12345

namespace :migrations do
  desc "deactivating dependent"
  DeactivatingFamilyMember.define_task :deactivating_family_member => :environment
end
