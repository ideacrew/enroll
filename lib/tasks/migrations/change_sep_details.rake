require File.join(Rails.root, "app", "data_migrations", "change_sep_details")
# This rake task is to change SEP details
# RAILS_ENV=production bundle exec rake migrations:change_sep_details sep_id='580e5f31082e766296006dd2' action="change_market_kind"
namespace :migrations do
  desc "change_sep_details"
  ChangeSepDetails.define_task :change_sep_details => :environment
end
