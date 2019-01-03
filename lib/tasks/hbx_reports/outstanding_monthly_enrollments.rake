require "#{Rails.root}/app/helpers/config/aca_helper"
require File.join(Rails.root, "app", "reports", "hbx_reports", "outstanding_monthly_enrollments")
include Config::AcaHelper
# The idea behind this report is to get a list of all of the enrollments for an employer and what is currently in Glue. 
# Steps
# 1) You need to pull a list of enrollments from glue (bundle exec rails r script/queries/print_all_policy_ids > all_glue_policies.txt -e production)
# 2) Place that file into the Enroll Root directory. 
# 3) Run the below rake task
# RAILS_ENV=production bundle exec rake reports:outstanding_monthly_enrollments start_date='02/01/2019'

namespace :reports do 
  desc "Outstanding Enrollments by Employer"
    OutstandingMonthlyEnrollments.define_task :outstanding_monthly_enrollments => :environment
end
  