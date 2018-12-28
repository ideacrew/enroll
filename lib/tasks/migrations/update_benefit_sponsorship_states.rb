# Rake tasks used to remove the old aasm_states(initial states) of benefit sponsorships. Also introducing binder_paid state on Benefit Application.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_benefit_sponsorship_states
require File.join(Rails.root, "app", "data_migrations", "update_benefit_sponsorship_states")

namespace :migrations do
  desc "Updating the aasm_state of benefit sponsorships and benefit applications"
  UpdateBenefitSponosorshipStates.define_task :update_benefit_sponsorship_states => :environment
end