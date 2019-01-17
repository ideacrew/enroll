require File.join(Rails.root, "app", "data_migrations", "remove_duplicate_broker_agency_accounts")

# RAILS_ENV=production bundle exec rake migrations:remove_duplicate_broker_agency_accounts

namespace :migrations do
  desc "remove "
  RemoveDuplicateBrokerAgencyAccounts.define_task :remove_duplicate_broker_agency_accounts => :environment
end