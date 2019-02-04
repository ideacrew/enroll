require File.join(Rails.root, "app", "data_migrations", "add_consumer_role_for_family_member")
# This rake task is to add consumer role for family member that has person attached. 
#If the family member is primary applicant 
# RAILS_ENV=production bundle exec rake migrations:add_consumer_role_for_family_member family_member_id=1234 is_applicant="true"
#If the family member is not primary applicant
# RAILS_ENV=production bundle exec rake migrations:add_consumer_role_for_family_member family_member_id=1234 is_applicant="false"
namespace :migrations do
  desc "adding consumer role for family member"
  AddConsumerRoleForFamilyMember.define_task :add_consumer_role_for_family_member => :environment
end 
