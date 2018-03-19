# Rake task to update Medicaid Eligibility of a Person
# RAILS_ENV=production bundle exec rake migrations:update_medicaid_eligibility primary_id="07255ef0b48f4defad0824d285cc3f21" dependents_ids="07255ef0b48f4defad0824d285cc3f21,17255ef1b24f4defad0824d285dd3f21" eligiblility_year="2018"

require File.join(Rails.root, "app", "data_migrations", "update_medicaid_eligibility")

namespace :migrations do
  desc "Update Medicaid Eligibility of a Person"
  UpdateMedicaidEligibility.define_task :update_medicaid_eligibility => :environment
end
