require File.join(Rails.root, "app", "data_migrations", "activate_family_member")
# This rake task will activate a family member
# RAILS_ENV=production bundle exec rake migrations:activate_family_member family_member_id=123123123

namespace :migrations do
  desc "set is_active in family_member to true"
  ActivateFamilyMember.define_task :activate_family_member => :environment
end
