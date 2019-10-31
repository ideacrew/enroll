require File.join(Rails.root, "app", "data_migrations", "migrate_brokers_as_exempt_organizations")
# This rake task is to migrate brokers as exempt organiaztions
# RAILS_ENV=production bundle exec rake migrations:migrate_brokers_as_exempt_organizations

namespace :migrations do
  desc "migrate_brokers_as_exempt_organizations"
  MigrateBrokersAsExemptOrganizations.define_task :migrate_brokers_as_exempt_organizations => :environment
end