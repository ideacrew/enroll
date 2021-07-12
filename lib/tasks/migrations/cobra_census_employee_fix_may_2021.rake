# Rake task to fix census employees cobra issue
# To run rake task: RAILS_ENV=production bundle exec rake migrations:CobraCensusEmployeeFixMay2021 file_name="95047_cobra_enrollment_issue_report.csv"

require File.join(Rails.root, "app", "data_migrations", "cobra_census_employee_fix_may_2021")
namespace :migrations do
  desc "Fixing census employee cobra issues may 2021"
  CobraCensusEmployeeFixMay2021.define_task :CobraCensusEmployeeFixMay2021 => :environment
end
