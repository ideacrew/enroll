require File.join(Rails.root, "app", "data_migrations", "activate_or_deactivate_employer_link_for_broker")
# This rake task is to enable or disable employer link for a broker
# RAILS_ENV=production bundle exec rake migrations:activate_or_deactivate_employer_link_for_broker plan_design_org_id="sdjb43743vhg34"

namespace :migrations do
  desc "enabling employer link for a broker"
  ActivateOrDeactivateEmployerLinkForBroker.define_task :activate_or_deactivate_employer_link_for_broker => :environment
end
