require File.join(Rails.root, "app", "data_migrations", "remove_congress_census_employee")
# This rake task is to remove census employee from congress only
# RAILS_ENV=production bundle exec rake migrations:remove_congress_census_employee census_employee_id=5968c35ef1244e2b4f000008

namespace :migrations do
  desc "remove unlinked congressional census employee"
  RemoveCongressCensusEmployee.define_task :remove_congress_census_employee => :environment
end