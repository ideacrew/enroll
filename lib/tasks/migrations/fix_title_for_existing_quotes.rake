# This rake task is used to deactivate POC from employer account.
# RAILS_ENV=production bundle exec rake migrations:fix_title_for_existing_quotes
require File.join(Rails.root, "app", "data_migrations", "fix_title_for_existing_quotes")

namespace :migrations do
  desc "change fein of an organization"
  FixTitleForExistingQuotes.define_task :fix_title_for_existing_quotes => :environment
end
