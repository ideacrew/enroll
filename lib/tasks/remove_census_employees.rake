require File.join(Rails.root, "app", "data_migrations", "remove_census_employees")

# This rake task is to delete census employees under an organization
# format: RAILS_ENV=production bundle exec rake migrations:remove_census_employees fein=122344555
namespace :migrations do
  desc "Deleting Census Employees "
  RemoveCensusEmployees.define_task :remove_census_employees => :environment
end