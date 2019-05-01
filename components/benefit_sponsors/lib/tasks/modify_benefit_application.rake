require File.join(File.dirname(__FILE__), "..", "..", "app", "data_migrations", "modify_benefit_application")

# This rake task is to modify benefit applications - canceling, terminating, re-instating and updating aasm state.
# pass termination_notice="true" in order to send termination notice to both employer and employees
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=531828 termination_date="12/01/2016" end_on="12/01/2016" action="terminate" termination_notice="true" off_cycle_renewal="true"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="cancel"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="reinstate"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="begin_open_enrollment" effective_date="09/01/2018"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="force_submit_application" effective_date="09/01/2018"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=531828 effective_date="12/01/2016" new_start_date="12/01/2016" new_end_date="12/01/2016" action="update_effective_period_and_approve"

namespace :migrations do
  desc "Modifying benefit applications - Cancel, Terminate, Re-instate, Update Aasm State"
  ModifyBenefitApplication.define_task :modify_benefit_application => :environment
end
