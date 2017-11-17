require File.join(Rails.root, "app", "data_migrations", "trigger_broker_invitation_url")
# This rake task is to send invitation url to the broker
# RAILS_ENV=production bundle exec rake migrations:trigger_broker_invitation broker_npn=3657876

namespace :migrations do
  desc "trigger broker invitation url"
  TriggerBrokerInvitationUrl.define_task :trigger_broker_invitation => :environment
end