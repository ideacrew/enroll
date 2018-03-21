# RAILS_ENV=production bundle exec rake migrations:move_all_verification_types_to_model

require File.join(Rails.root, "app", "data_migrations", "migrate_verification_types")

namespace :migrations do
  desc "Migrate all verification types to a new model"
  MigrateVerificationTypes.define_task :move_all_verification_types_to_model => :environment
end