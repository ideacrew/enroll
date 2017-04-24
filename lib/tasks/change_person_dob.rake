require File.join(Rails.root, "app", "data_migrations", "change_person_dob")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:change_person_dob  hbx_id=123123123 new_dob=Date.new(2011,1,1)

namespace :migrations do
  desc "change_person_dob"
  ChangeFein.define_task :change_person_dob => :environment
end