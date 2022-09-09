# RAILS_ENV=production bundle exec rake migrations:AddPrimaryFamilyToPerson
# Rake task to add a primary family to a person and their dependents if applicable
# Interactive rake that takes input from the user to be completed

require File.join(Rails.root, "app", "data_migrations","rake", "add_primary_family_to_person")

namespace :migrations do
  desc "Add Primary Family to Person"
  AddPrimaryFamilyToPerson.define_task :add_primary_family_to_person => :environment
end
