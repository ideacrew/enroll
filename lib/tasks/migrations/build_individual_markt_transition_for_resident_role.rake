#RAILS_ENV=production bundle exec rake migrations:build_individual_market_transition_for_resident_role hbx_id=198767889 action="build_individual_transition_for_resident_role"
require File.join(Rails.root, "app", "data_migrations", "build_individual_market_transition_for_resident_role")

namespace :migrations do
  desc "build individual market transitions for resident role"
  BuildIndividualMarketTransitionForResidentRole.define_task :build_individual_market_transition_for_resident_role => :environment
end