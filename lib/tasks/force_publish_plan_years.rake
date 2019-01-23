require File.join(Rails.root, "app",'data_migrations', "force_publish_plan_years")
# This rake task adds a new person under covered in the existing enrollment
# RAILS_ENV=production bundle exec rake migrations:force_publish_plan_years start_on_date="1/1/2019" current_date="11/30/2018" query_count_only="true"
namespace :migrations do
  desc "force publish plan years"
  ForcePublishPlanYears.define_task :force_publish_plan_years => :environment 
end 