require File.join(Rails.root, "app", "data_migrations", "change_suffix_person")
# This rake task is to change the name suffix of a person
# RAILS_ENV=production bundle exec rspec spec/data_migrations/change_suffix_person_spec.rb
namespace :migrations do
  desc "changing person suffix"
  ChangeSuffixPerson.define_task :change_suffix_person => :environment
end 
