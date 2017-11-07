require File.join(Rails.root, "app", "data_migrations", "assign_attested_residency_state")
# This rake task is to update local residency as attested for every consumer with active enrollment at the moment this task will run
#the task has to be run onbly once!!! don't rerun it later because it will update
# RAILS_ENV=production bundle exec rake migrations:change_person_dob  hbx_id=123123123 new_dob=“02/03/2016"

namespace :migrations do
  desc "assign_attested_residency_state"
  AssignAttestedResidency.define_task :assign_attested_residency_state => :environment
end