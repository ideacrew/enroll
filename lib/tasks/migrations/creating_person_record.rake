require File.join(Rails.root, "app", "data_migrations", "creating_person_record")
# This rake task is to create a new initial plan year using parameters of an existing plan year
# RAILS_ENV=production bundle exec rake migrations:creating_person_record
namespace :migrations do
  desc "creating person records"
  CreatingPersonRecord.define_task :creating_person_record => :environment
end
