require File.join(Rails.root, "app", "data_migrations", "products", "mapping_to_correct_hios_id")
# This rake task is to map the correct hios_id for the proudcts
# This rake task is to update product_id of hbx_enrollment with it's same reference_product_id
# RAILS_ENV=production bundle exec rake migrations:mapping_to_correct_hios_id feins="787878677,128953935" hios_id="82569MA0250001-01"

namespace :migrations do
  desc "map previous year dental plans with current year dental plans"
  MappingToCorrectHiosId.define_task :mapping_to_correct_hios_id => :environment
end