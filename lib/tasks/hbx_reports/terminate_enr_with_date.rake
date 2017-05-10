# Rake task to terminate enrollment with a given date
# To run rake task: RAILS_ENV=production bundle exec rake migrations:terminate_enr_with_date person_hbx_id="184115" enr_hbx_id="210100" terminated_on="7/31/16"

require File.join(Rails.root, "app", "data_migrations", "terminate_enr_with_date")
namespace :migrations do
  desc "Terminate enrollment with a given date"
  TerminateEnrWithDate.define_task :terminate_enr_with_date => :environment
end
