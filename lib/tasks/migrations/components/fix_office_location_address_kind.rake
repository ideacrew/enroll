require File.join(Rails.root, "app", "data_migrations", "components", "fix_office_location_address_kind")

# This rake task used to update employer primary office location kind from work to primary
# RAILS_ENV=production bundle exec rake migrations:fix_office_location_address_kind

namespace :migrations do
  desc "Fix employer primary office location address kind"
  FixOfficeLocationAddressKind.define_task :fix_office_location_address_kind => :environment
end

