require File.join(Rails.root, "app", "data_migrations", "update_broker_agency_profile_id_for_broker_agency_staff_role")

# This rake task is to update the broker agency profile id for broker_agency_staff_role
# format: RAILS_ENV=production bundle exec rake migrations:update_broker_agency_profile_id person_hbx_id=544544 broker_agency_staff_role_id=123123123 broker_agency_profile_id
namespace :migrations do
  desc "updating broker agency profile id for a specific broker agency staff role"
  UpdateBrokerAgencyProfileIdForBrokerAgencyStaffRole.define_task :update_broker_agency_profile_id_for_broker_agency_staff_role => :environment
end