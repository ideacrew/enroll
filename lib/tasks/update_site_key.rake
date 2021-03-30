# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "update_site_key")

# This rake task is to update the site key
# format: RAILS_ENV=production bundle exec rake migrations:update_site_key new_site_key="me"
namespace :migrations do
  desc "updating site key"
  UpdateSiteKey.define_task :update_site_key => :environment
end