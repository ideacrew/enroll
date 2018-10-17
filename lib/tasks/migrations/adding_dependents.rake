require File.join(Rails.root, "app", "data_migrations", "adding_dependents")

# RAILS_ENV=production bundle exec rake migrations:adding_dependents family_id="5b43aaba73e54e55a4000028" file_name="dependents.csv" 

namespace :migrations do
  desc "adding_dependents"
  AddingDependents.define_task :adding_dependents => :environment
end
