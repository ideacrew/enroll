require File.join(Rails.root, "app", "data_migrations", "remove_old_ifsv_cases")
# This rake task is to remove specified hbx_enrollments and people records
# RAILS_ENV=production bundle exec rake migrations:remove_old_ifsv_cases.rb HBX_IDS=123,456 SSNS=123456789,987654321

namespace :migrations do
  desc "remove hbx_enrollments and people records by HBX ID and SSN"
  RemoveSsn.define_task :remove_old_ifsv_cases => :environment
end
