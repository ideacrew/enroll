# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:add_primary_family dep_hbx_id="123456789"

require File.join(Rails.root, "app", "data_migrations", "add_primary_family")
namespace :migrations do
  desc "add_primary_family"
  AddPrimaryFamily.define_task :add_primary_family => :environment
end