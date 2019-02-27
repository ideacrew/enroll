require File.join(Rails.root, "app", "data_migrations", "new_exempt_organization")
# This rake task is to move hbx_enrollment between two accounts
# RAILS_ENV=production bundle exec rake migrations:new_exempt_organization fein=362739571 legal_name="UnitedHealthcare" abbreviation="UHIC" hbx_carrier_id="20014" issuer_hios_ids="31779" shop_health=true
# RAILS_ENV=production bundle exec rake migrations:new_exempt_organization fein=050513223 legal_name="Altus" abbreviation="ALT" hbx_carrier_id="20001" issuer_hios_ids="18076" shop_dental=true
# RAILS_ENV=production bundle exec rake migrations:new_exempt_organization fein=046143185 legal_name="Delta Dental" abbreviation="DDA" hbx_carrier_id="20004" issuer_hios_ids="80538,11821" shop_dental=true

namespace :migrations do
  desc "new_exempt_organization"
  NewExemptOrganization.define_task :new_exempt_organization => :environment
end