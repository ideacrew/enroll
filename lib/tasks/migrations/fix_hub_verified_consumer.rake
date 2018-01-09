require File.join(Rails.root, "app", "data_migrations", "fix_hub_verified_consumer")

# RAILS_ENV=production bundle exec rake migrations:fix_hub_verified_consumer event_name=fix_unverified_people
# RAILS_ENV=production bundle exec rake migrations:fix_hub_verified_consumer event_name=fix_outstanding_people
# RAILS_ENV=production bundle exec rake migrations:fix_hub_verified_consumer
namespace :migrations do
  desc "fix hub verified consumer"
  FixHubVerifiedConsumer.define_task :fix_hub_verified_consumer => :environment
end