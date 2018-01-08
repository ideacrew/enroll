# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:add_benefit_group_id hbx_id="123456789"

require File.join(Rails.root, "app", "data_migrations", "add_benefit_group_id")
namespace :migrations do
  desc "add_benefit_group_id"
  AddBenefitGroupId.define_task :add_benefit_group_id => :environment
end