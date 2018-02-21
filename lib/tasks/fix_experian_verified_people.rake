require File.join(Rails.root, "app", "data_migrations", "fix_experian_verified_people")
# The task to run is RAILS_ENV=production bundle exec rake migrations:fix_experian_verified_people

namespace :migrations do
  desc 'Update citizen status for people who are fully verified but not lawfully present'
  FixExperianVerifiedPeople.define_task fix_experian_verified_people: :environment
end