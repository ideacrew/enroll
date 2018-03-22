require File.join(Rails.root, "app", "data_migrations", "correct_not_lawfully_citizen_status")
# The task to run is RAILS_ENV=production bundle exec rake migrations:update_not_lawfully_present_citizen_status

namespace :migrations do
  desc 'Update citizen status for people who are not lawfully present'
  CorrectNotLawfullyCitizenStatus.define_task update_not_lawfully_present_citizen_status: :environment
end
