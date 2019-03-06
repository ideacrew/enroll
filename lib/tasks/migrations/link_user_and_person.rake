require File.join(Rails.root, "app", "data_migrations", "link_user_and_person")
# This rake task is to link a user to a person account
# RAILS_ENV=production bundle exec rake migrations:link_user_and_person person_hbx_id="19901804" user_id="123123123"
namespace :migrations do
  desc "link_user_and_person"
  LinkUserAndPerson.define_task :link_user_and_person => :environment
end
