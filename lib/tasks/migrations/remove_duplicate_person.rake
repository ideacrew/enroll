require File.join(Rails.root, "app", "data_migrations", "remove_duplicate_person")
# This rake task is to remove invalid benefit group assignment under census employee
# RAILS_ENV=production bundle exec rake migrations:remove_duplicate_person ssn=523277 first_name=first_name last_name=last_name dob=1968-05-12
namespace :migrations do
  desc "remove duplicate person"
  RemoveDuplicatePerson.define_task :remove_duplicate_person => :environment
end