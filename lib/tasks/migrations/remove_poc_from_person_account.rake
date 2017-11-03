# Rake tasks used to remove employer staff roles of the invalid person account
# To run rake task: RAILS_ENV=production bundle exec rake migrations:remove_invalid_broker_agency_accounts_for_employer fein=800059771
require File.join(Rails.root, "app", "data_migrations", "remove_poc_from_person_account")

namespace :migrations do
  desc "Remove poc from person account"
  RemovePocFromPersonAccount.define_task :remove_poc_from_person_account => :environment
end