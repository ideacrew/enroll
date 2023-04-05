require File.join(Rails.root, "app",'data_migrations', "employee_renewals_export")
# These rakes manage the force publish process and generate reports

# This rake only builds the detail report of enrollments and their statuses
# RAILS_ENV=production bundle exec rake migrations:employee_renewals_export start_on_date="5/1/2023"

namespace :migrations do
  desc "force publish benefit applications and generating reports"
  EmployeeRenewalsExport.define_task :employee_renewals_export => :environment 
end 
