require File.join(Rails.root, "app", "data_migrations", "remove_enrolled_contingent_state")
# This rake task is to migrate hbx_enrollments to get rid of enrolled_contingent state
# RAILS_ENV=production bundle exec rake migrations:remove_enrolled_contingent_state

namespace :migrations do
  desc "remove_enrolled_contingent_state"
  RemoveEnrolledContingentState.define_task :remove_enrolled_contingent_state => :environment
end
