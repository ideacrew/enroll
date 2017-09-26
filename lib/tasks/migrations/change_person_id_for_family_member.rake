require File.join(Rails.root, "app", "data_migrations", "change_person_id_for_family_member")
# RAILS_ENV=production bundle exec rake migrations:change_person_id_for_family_member person_hbx_id family_member_id dependent_hbx_id
namespace :migrations do
  desc "change person id for family member"
  ChangePersonIdForFamilyMember.define_task :change_person_id_for_family_member => :environment
end