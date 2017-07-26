require File.join(Rails.root, "app", "data_migrations", "update_broker_phone_kind")
# This rake task is to change the broker phone kind
# RAILS_ENV=production bundle exec rake migrations:update_broker_phone_kind fein=999990069
namespace :migrations do
  desc "Changing the broker phone kind"
  UpdateBrokerPhoneKind.define_task :update_broker_phone_kind => :environment
end 