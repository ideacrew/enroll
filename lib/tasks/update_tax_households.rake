# This rake task is to 're-activate' a THH that may have been end-dated during the time of open enrollment.
# The UpdateEligibility script when importing Eligibility for the next year during OE end dates all the prior THHs.
# Example: So there is a scenario that you may still be in 2017 and due to the import of 2018 Eligibility it would end date all 2017 THH.
# This leaves the family being unable to shop using 2017 Eligibility, so the fix is to revert the end dated THH (latest THH for that year) for these cases.

require File.join(Rails.root, "app", "data_migrations", "update_tax_households")

namespace :migrations do
  desc "set the THH effective_ending_on to nil"
  UpdateTaxHouseholds.define_task :update_effective_ending_on => :environment
end


