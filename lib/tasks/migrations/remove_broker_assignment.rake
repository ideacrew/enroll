require File.join(Rails.root, "app", "data_migrations", "remove_broker_assignment")
# This rake task is to remove the broker assignment for a family with given person hbx_id
# RAILS_ENV=production bundle exec rake migrations:remove_broker_assignment hbx_id="178211"
# RAILS_ENV=production bundle exec rake migrations:remove_broker_assignment hbx_id="190385"
namespace :migrations do
  desc "removing broker assignment for a family ith given person hbx_id"
  RemoveBrokerAssignment.define_task :remove_broker_assignment => :environment
end
