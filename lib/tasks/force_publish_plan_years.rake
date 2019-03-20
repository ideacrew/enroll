require File.join(Rails.root, "app",'data_migrations', "force_publish_plan_years")
# These rakes manage the force publish process

# This rake only builds the detail report of enrollments and their statuses
# RAILS_ENV=production bundle exec rake migrations:force_publish_plan_years start_on_date="5/1/2019" current_date="3/20/2019" detail_report_only="true" 

# This rake only returns the enrollment count
# RAILS_ENV=production bundle exec rake migrations:force_publish_plan_years start_on_date="1/1/2019" current_date="11/30/2018" query_count_only="true" 

# This rake builds the unassigned packages report and attempts to save the EEs
# RAILS_ENV=production bundle exec rake migrations:force_publish_plan_years start_on_date="1/1/2019" current_date="11/30/2018" only_assign_packages="true" 

# This rake will only build the detail and non detailed report of enrollment statuses
# RAILS_ENV=production bundle exec rake migrations:force_publish_plan_years start_on_date="3/1/2019" current_date="1/23/2019" reports_only="true"

# This rake will run the entire force publish process
# RAILS_ENV=production bundle exec rake migrations:force_publish_plan_years start_on_date="5/1/2019" current_date="3/21/2019" 

namespace :migrations do
  desc "force publish plan years"
  ForcePublishPlanYears.define_task :force_publish_plan_years => :environment 
end 