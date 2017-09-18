require File.join(Rails.root, "app", "data_migrations", "remove_decertified_pending_brokers_from_families")

# RAILS_ENV=production bundle exec rake migrations:remove_decertified_pending_brokers_from_families

namespace :migrations do
  desc "remove "
  RemoveDertifiedPendingBrokersFromFamilies.define_task :remove_decertified_pending_brokers_from_families => :environment
end