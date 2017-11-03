# RAILS_ENV=production bundle exec rake migrations:generate_report_for_bad_eligibile_families
# Rake to generate a CSV with list of families that have bad eligiblity determination.

require File.join(Rails.root, "app", "data_migrations", "generate_report_for_bad_eligibile_families")

namespace :migrations do
  desc "List of Families with bad eligibility determination"
  GenerateReportForBadEligibileFamilies.define_task :generate_report_for_bad_eligibile_families => :environment
end
