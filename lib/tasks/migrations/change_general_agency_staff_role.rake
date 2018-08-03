# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:change_general_agency_staff_role incorrect_person_hbx_id="19748191" correct_person_hbx_id="123123"

require File.join(Rails.root, "app", "data_migrations", "change_general_agency_staff_role")
namespace :migrations do
  desc "change_general_agency_staff_role"
  ChangeGeneralAgencyStaffRole.define_task :change_general_agency_staff_role => :environment
end
