require File.join(Rails.root, "app", "data_migrations", "update_family_member_details")
#RAILS_ENV=production bundle exec rake migrations:update_family_member_details hbx_id_1="6466" hbx_id_2="786868" id="155757678"
namespace :migrations do
  desc "updating family member info"
  UpdateFamilyMemberDetails.define_task :update_family_member_details => :environment
end
