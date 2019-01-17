require File.join(Rails.root, "app", "data_migrations", "change_person_family_member_linkage")
# This rake task is to change the linkage between a person and a family member. 
# RAILS_ENV=production bundle exec rake migrations:change_person_family_member_linkage hbx_id='person hbx id' family_member_id='mongo id of the family member'
namespace :migrations do
  desc "changing person family member linkage"
  ChangePersonFamilyMemberLinkage.define_task :change_person_family_member_linkage => :environment
end
