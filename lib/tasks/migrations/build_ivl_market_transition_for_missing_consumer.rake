#RAILS_ENV=production bundle exec rake migrations:build_individual_market_transition_for_missing_consumer action="clear_all_cases"
#RAILS_ENV=production bundle exec rake migrations:build_individual_market_transition_for_missing_consumer hbx_id=198767889 action="build_ivl_transitions"
require File.join(Rails.root, "app", "data_migrations", "build_ivl_market_transition_for_missing_consumer")

namespace :migrations do
  desc "build individual market transitions for missing consumers"
  BuildIvlMarketTransitionForMissingConsumer.define_task :build_individual_market_transition_for_missing_consumer => :environment
end