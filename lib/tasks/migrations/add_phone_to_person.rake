require File.join(Rails.root, "app", "data_migrations", "add_phone_to_person")
# This rake task is to add a new phone record to a person
# RAILS_ENV=production bundle exec rake migrations:add_phone_to_person hbx_id=900000000 full_phone_number=1234567890 kind="work"

namespace :migrations do
  desc "add phone to person"
  AddPhoneToPerson.define_task :add_phone_to_person => :environment
end
