require File.join(Rails.root, "app", "data_migrations", "change_broker_details")

# This rake task is to update the broker role details
# format: RAILS_ENV=production bundle exec rake migrations:change_broker_details hbx_id=5675 new_market_kind="New Name"
namespace :migrations do
  desc "updating broker's market kind"
  ChangeBrokerDetails.define_task :change_broker_details => :environment
end