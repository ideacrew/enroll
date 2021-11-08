require File.join(Rails.root, "app", "data_migrations", "link_keycloak_accounts_for_users")
# This rake task is to create keycloak accounts for users and update users with keycloak account ids
# RAILS_ENV=production bundle exec rake migrations:link_keycloak_accounts_for_users
namespace :migrations do
  desc "create keycloak accounts and update users with keycloak account ids"
  LinkKeycloakAccountsForUsers.define_task :link_keycloak_accounts_for_users => :environment
end 
