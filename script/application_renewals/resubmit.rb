# frozen_string_literal: true

require 'csv'

# This script is used to resubmit the renewal applications that are "stuck" in the 'renewal_draft' or 'submitted' state.
# Pass the renewal year as an argument to the script to resubmit the renewal applications for that year.
# renewal_year=2025 bundle exec rails runner script/application_renewals/resubmit.rb

renewal_year = ENV['renewal_year']
return puts "Please pass renewal year as an argument to the script. Example: renewal_year=2025 bundle exec rails runner script/application_renewals/resubmit.rb" if renewal_year.blank?

results = ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::Resubmit.new.call({ renewal_year: renewal_year.to_i })

if results.failure?
  return puts "Failure: #{results.failure}"
else
  resubmissions = results.success
  file_path = "resubmit_renewal_applications_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
  CSV.open(file_path, 'wb') do |csv|
    csv << resubmissions.first.keys
    resubmissions.each do |resubmission_details|
      csv << resubmission_details.values
    end
  end
  puts "Process complete. Results are logged in #{file_path}" unless Rails.env.test?
end