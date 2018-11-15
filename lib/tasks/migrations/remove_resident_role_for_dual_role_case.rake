require File.join(Rails.root, "app", "data_migrations", "remove_resident_role_for_dual_role_case")
 #This rake task is used to remove the resident rolefor a person who have both employee role and resident role
 #RAILS_ENV=production bundle exec rake migrations:remove_resident_role_for_dual_role_case hbx_id="12345678"
 namespace :migrations do
   desc "remove_resident_role_for_dual_role_case"
   RemoveResidentRoleForDualRoleCase.define_task :remove_resident_role_for_dual_role_case => :environment
 end

