require File.join(Rails.root, "app", "data_migrations", "components", "fix_benefit_sponsorship_state")

# This rake task used to update employer benefit sponsorship aasm state
# RAILS_ENV=production bundle exec rake migrations:fix_benefit_sponsorship_state

namespace :migrations do
  desc "fix benefit sponsorship aasm state"
  FixBenefitSponsorshipState.define_task :fix_benefit_sponsorship_state => :environment
end
