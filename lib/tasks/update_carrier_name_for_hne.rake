require File.join(Rails.root, "app", "data_migrations", "update_carrier_name_for_hne")
# This rake task adds a new person under covered in the existing enrollment
# RAILS_ENV=production bundle exec rake migrations:update_carrier_name_for_hne
namespace :migrations do
  desc "update health new england carrier legal name"
  UpdateCarrierNameForHne.define_task :update_carrier_name_for_hne => :environment
end