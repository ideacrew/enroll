require File.join(Rails.root, "app", "data_migrations", "update_sep_market_kind")

# RAILS_ENV=production bundle exec rake migrations:update_sep_market_kind
namespace :migrations do
  desc "adding coverage household member"
  UpdateSepMarketKind.define_task :update_sep_market_kind => :environment
end 
