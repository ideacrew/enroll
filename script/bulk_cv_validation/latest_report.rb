# frozen_string_literal: true

# This script generates the latest CV Validation Job report for the families.
#
# Command to trigger the script:
#   CLIENT=me row_limit_per_file='10000' bundle exec rails runner script/bulk_cv_validation/latest_report.rb

p '********** STARTING - Script to generate the latest CV Validation Job report for all the families **********'

# Checks if the :families_cv_validation_job feature is enabled in the EnrollRegistry.
# If the feature is not enabled, it prints a message and exits the script.
#
# @return [void]
unless EnrollRegistry.feature_enabled?(:families_cv_validation_job)
  puts 'The bulk CV Validation Job for all the families feature is not enabled. Please enable the feature :families_cv_validation_job to run this script. EXITING.'
  exit
end

# Retrieves the row limit per file from the environment variable.
# If the row limit is not a positive integer, it prints a message and exits the script.
#
# @return [void]
row_limit_per_file = ENV['row_limit_per_file']
if row_limit_per_file.to_i <= 0
  puts 'Please pass row_limit_per_file as a positive integer. EXITING.'
  exit
end

# Calls the operation to generate the latest CV Validation Job report and handles the result.
# If the job is successful, it logs the success message and instructions.
# If the job fails, it logs the failure message.
#
# @return [void]
result = ::Operations::Reports::Families::CvValidationJobs::LatestReport.new.call({ jobs_per_iteration: row_limit_per_file.to_i })

if result.success?
  puts result.success
  puts "Multiple CSVs and a log file are created with matching names latest_cv_validation_job_report_*.csv & latest_cv_validation_job_logger_*.log."
  puts "***** PLEASE RETRIEVE THEM, PASSWORD PROTECT, AND ATTACH TO THE PIVOTAL STORY. *****"
else
  puts result.failure
end

p '********** FINISHED - Script to generate the latest CV Validation Job report for all the families **********'
