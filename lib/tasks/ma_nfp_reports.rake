require File.join(Rails.root, "app", "data_migrations", "ma_nfp_reports")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:ma_nfp_reports start_on="06/01/2019"

namespace :migrations do
  desc "ma_nfp_reports"
  MaNfpReports.define_task :ma_nfp_reports => :environment
end