require File.join(Rails.root, "app", "reports", "hbx_reports", "primary_subscribers_data_with_e_case_id")
 # This will generate a csv file containing primary subscribers of EA associated with integrated case.
 # The task to run is RAILS_ENV=production bundle exec rake reports:primary_subscriber:with_e_case_id
 namespace :reports do
   namespace :primary_subscriber do
 
     desc "List of all Primary Subscribers in Enroll with an associated integrated case"
     PrimarySubscribersDataWithECaseId.define_task  :with_e_case_id => :environment

   end
 end