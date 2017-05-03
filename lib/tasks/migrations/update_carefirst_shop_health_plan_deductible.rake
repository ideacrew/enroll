# this rake task is for merge the er account to the ee account
# er has user, ee has no user
#expected outcome is to access the ee account from user login

require File.join(Rails.root, "app", "data_migrations", "update_carefirst_shop_health_plan_deductible")

# RAILS_ENV=production bundle exec rake migrations:update_carefirst_shop_health_plan_deductible
namespace :migrations do
  desc "update_carefirst_shop_health_plan_deductible"
  UpdateCarefirstShopHealthPlanDeductible.define_task :update_carefirst_shop_health_plan_deductible => :environment
end