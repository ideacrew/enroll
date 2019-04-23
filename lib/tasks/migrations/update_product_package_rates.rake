# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_product_package_rates feins="12454214"

require File.join(Rails.root, "app", "data_migrations", "update_product_package_rates")
namespace :migrations do
  desc "update_product_package_rates"
  UpdateProductPackageRates.define_task :update_product_package_rates => :environment
end