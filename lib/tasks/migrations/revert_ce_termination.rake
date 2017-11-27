require File.join(Rails.root, "app", "data_migrations", "revert_ce_termination")
# This rake task is to revert the termination of the census employee that is currently in termination_pending status
# RAILS_ENV=production bundle exec rake migrations:revert_ce_termination census_employee_id=580e456cfaca142b4a00006d
namespace :migrations do
  desc "revert ce_termination"
  RevertCeTermination.define_task :revert_ce_termination => :environment
end
