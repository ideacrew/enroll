require File.join(Rails.root, "app", "data_migrations", "load_issuer_profiles")

# RAILS_ENV=production bundle exec rake migrations:load_issuer_profiles
namespace :migrations do
  desc "new_exempt_organization"
  LoadIssuerProfiles.define_task :load_issuer_profiles => :environment
end