#RAILS_ENV=production bundle exec rake migrations:build_individual_market_transition_for_person_record hbx_id=198767889 action="build_ivl_transitions"
#RAILS_ENV=production bundle exec rake migrations:build_individual_market_transition_for_person_record hbx_id=198767889 action="build_resident_transitions"

require File.join(Rails.root, "app", "data_migrations", "build_ivl_market_transition_for_person_record")

namespace :migrations do
  desc "build individual market transitions for person record"
  BuildIvlMarketTransitionForPersonRecord.define_task :build_individual_market_transition_for_person_record => :environment
end