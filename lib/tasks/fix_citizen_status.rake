require File.join(Rails.root, "app", "data_migrations", "fix_citizen_status")
# The task to run is RAILS_ENV=production bundle exec rake migrations:update_citizen_status_not_lawfully_present

namespace :migrations do
  desc 'Update citizen status for people who are fully verified but not lawfully present'
  FixCitizenStatus.define_task update_citizen_status_not_lawfully_present: :environment
end