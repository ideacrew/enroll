require File.join(Rails.root, 'app', 'data_migrations', 'add_broker_agency_staff_role_for_broker')
# This rake task is to add broker agency staff role for a certified broker
# RAILS_ENV=production bundle exec rake migrations:add_broker_agency_staff_role_for_broker
namespace :migrations do
  desc 'adding or removing enrollment members'
  AddBrokerAgencyStaffRoleForBroker.define_task :add_broker_agency_staff_role_for_broker => :environment
end