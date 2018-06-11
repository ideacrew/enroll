require File.join(Rails.root, "app", "data_migrations", "remove_family_member")
# This rake task is to remove a duplicate family member using the first and last name
# RAILS_ENV=production bundle exec rake migrations:remove_family_member person_hbx_id="8767567" person_first_name=“Gavin,G” person_last_name=“vozar”

namespace :migrations do
  desc "remove family member"
  RemoveFamilyMember.define_task :remove_family_member => :environment
end