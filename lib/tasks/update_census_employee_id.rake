require File.join(Rails.root, "app", "data_migrations", "update_census_employee_id")
# This rake task is to update the person relationship kind
# RAILS_ENV=production bundle exec rake migrations:update_census_employee_id census_employee_id=5ba26cd3e59c4a47590000a6 employee_role_id='12'
namespace :migrations do
  desc "Changing census employee id for employee record"
  UpdateCensusEmployee.define_task :update_census_emp => :environment
end
