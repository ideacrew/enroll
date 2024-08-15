# frozen_string_literal: true

# This script initiates the bulk cv validation job for all the families.

# Command to trigger the script:
#   CLIENT=me bundle exec rails runner script/bulk_cv_validation/trigger_job.rb

# Checks if the :families_cv_validation_job feature is enabled in the EnrollRegistry.
# If the feature is not enabled, it prints a message and exits the script.
#
# @return [void]
unless EnrollRegistry.feature_enabled?(:families_cv_validation_job)
  puts 'The bulk CV Validation Job for all the families feature is not enabled. Please enable the feature :families_cv_validation_job to run this script. EXITING.'
  exit
end

# Calls the Bulk CV Validation Job and handles the result.
# If the job is successful, it logs the success message and instructions.
# If the job fails, it logs the failure message.
#
# @return [void]
result = ::Operations::Private::Families::BulkCvValidation::Request.new.call
if result.success?
  puts result.success
  puts "2 files (CSV and Log) are created with matching names bulk_cv_validation_logger_*.log and bulk_cv_validation_report_*.csv."
  puts "***** PLEASE RETRIEVE THEM, PASSWORD PROTECT, AND ATTACH TO THE PIVOTAL STORY. *****"
else
  puts result.failure
end
