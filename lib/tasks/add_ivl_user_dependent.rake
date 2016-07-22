require File.join(Rails.root, "app", "data_migrations", "add_ivl_user_dependent")
# This rake task creates coverage household member record for the family member with domestic partner relationship
# RAILS_ENV=production bundle exec rake migrations:add_ivl_user_dependent first_name=Campbell last_name=Marshall dob=12/04/1979
namespace :migrations do
  desc "adding coverage houshold to dependent with domestic partner relation"
  AddIvlUserDependent.define_task :add_ivl_user_dependent => :environment
end 