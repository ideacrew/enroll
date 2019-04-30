# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_predecessor_id_on_bp old_benefit_package_id=1322233131 renewing_benefit_package_id=215612565122

require File.join(Rails.root, "app", "data_migrations", "update_predecessor_id_on_bp")
namespace :migrations do
  desc "update_predecessor_id_on_bp"
  UpdatePredecessorIdOnBp.define_task :update_predecessor_id_on_bp => :environment
end