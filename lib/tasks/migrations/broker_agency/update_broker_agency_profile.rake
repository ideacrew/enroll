# This Rake should work for all broker instance updates
# Usage:
# RAILS_ENV=production bundle exec rake migrations:update_broker_agency action='update_fein' exist_fein="322323423423" new_fein="223423423"
# similarly for corporate_npn
# Other usage
# RAILS_ENV=production bundle exec rake migrations:update_broker_agency action='update_person' hbx_id="23424234" exist_fein="21231231"
#
# RAILS_ENV=production bundle exec rake migrations:update_broker_agency action='corporate_npn' exist_fein= "2234234234" new_npn="32324242"
require File.join(Rails.root, "app", "data_migrations", "update_broker_agency_details")

namespace :migrations do
  desc "link an employee for an employer"
  UpdateBrokerAgencyProfile.define_task :update_broker_agency => :environment
end
