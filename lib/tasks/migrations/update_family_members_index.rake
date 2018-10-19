require File.join(Rails.root, "app", "data_migrations", "update_family_members_index")
# This rake task is to swap the index of family members in family
# RAILS_ENV=production bundle exec rake migrations:update_family_members_index primary_hbx="19771145" dependent_hbx="19771142" primary_family_id="5689b6cc50526c597800004a" dependent_family_id="5689b5df50526c1ef7000151" 
# RAILS_ENV=production bundle exec rake migrations:update_family_members_index primary_hbx="19771145" old_family_id="19771142" correct_family_id="56894546" action_task="update_family_id"


namespace :migrations do
  desc "update_family_members_index"
  UpdateFamilyMembersIndex.define_task :update_family_members_index => :environment
end
