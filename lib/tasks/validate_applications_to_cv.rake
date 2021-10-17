require File.join(Rails.root, "app", "data_migrations", "validate_applications_to_cv")

# This rake task is to validate cv3 payload for imported applications
# format: RAILS_ENV=production bundle exec rake migrations:validate_applications_to_cv calender_year='2022'
namespace :migrations do
  desc "validate imported applications cv3 payload"
  ValidateApplicationsToCv.define_task :validate_applications_to_cv => :environment
end