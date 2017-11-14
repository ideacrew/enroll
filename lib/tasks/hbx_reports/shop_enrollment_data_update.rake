require File.join(Rails.root, "app", "data_migrations", "shop_enrollment_data_update")

namespace :migrations do
  desc "Correct the shop enrollment"
  ShopEnrollmentDataUpdate.define_task :shop_enrollment_data_update => :environment
end