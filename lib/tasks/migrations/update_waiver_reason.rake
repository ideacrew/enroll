#Rake task to update waiver reasons
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_waiver_reason id="756784" waiver_reason="I have coverage through Medicaid"
require File.join(Rails.root, "app", "data_migrations", "update_waiver_reason")
namespace :migrations do
  desc "update_waiver_reason"
  UpdateWaiverReason.define_task :update_waiver_reason => :environment
end