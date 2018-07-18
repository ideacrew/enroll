require File.join(Rails.root, "app", "data_migrations", "update_qle_tooltip")
#RAILS_ENV=production bundle exec rake migrations:update_qle_tooltip
namespace :migrations  do
  desc "update qle tooltip"
  UpdateQleTooltip.define_task :update_qle_tooltip => :environment
end
