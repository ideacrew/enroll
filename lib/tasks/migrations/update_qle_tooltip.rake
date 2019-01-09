require File.join(Rails.root, "app", "data_migrations", "update_qle_tooltip")
#RAILS_ENV=production bundle exec rake migrations:update_qle_tooltip title="Entered into a legal domestic partnership" text="Entering a domestic partnership as permitted or recognized by Massachusetts"
namespace :migrations  do
  desc "update qle tooltip"
  UpdateQleTooltip.define_task :update_qle_tooltip => :environment
end
