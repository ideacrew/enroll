require File.join(Rails.root, "app", "data_migrations", "correct_broker_ivl_families")
# This rake task is to add broker associated IVL families
# RAILS_ENV=production bundle exec rake migrations:correct_broker_ivl_families
namespace :migrations do
  desc "correct broker ivl families"
  CorrectBrokerIvlFamilies.define_task :correct_broker_ivl_families => :environment
end