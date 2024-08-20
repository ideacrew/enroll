# frozen_string_literal: true

# This script generates the latest CV Validation Job report for the families.

# Command to trigger the script:
#   CLIENT=me bundle exec rails runner script/bulk_cv_validation/latest_report.rb

# Checks if the :families_cv_validation_job feature is enabled in the EnrollRegistry.
# If the feature is not enabled, it prints a message and exits the script.
#
# @return [void]
unless EnrollRegistry.feature_enabled?(:families_cv_validation_job)
  puts 'The bulk CV Validation Job for all the families feature is not enabled. Please enable the feature :families_cv_validation_job to run this script. EXITING.'
  exit
end

# Calls the operation to generate the latest CV Validation Job report and handles the result.
# If the job is successful, it logs the success message and instructions.
# If the job fails, it logs the failure message.
#
# @return [void]
result = ::Operations::Reports::Families::CvValidationJobs::LatestReport.new.call
if result.success?
  puts result.success
  puts "2 files (CSV and Log) are created with matching names latest_cv_validation_job_logger_*.log and latest_cv_validation_job_report_*.csv."
  puts "***** PLEASE RETRIEVE THEM, PASSWORD PROTECT, AND ATTACH TO THE PIVOTAL STORY. *****"
else
  puts result.failure
end
