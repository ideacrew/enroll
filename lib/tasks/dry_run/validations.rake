require_relative 'utils'

namespace :dry_run do
  desc "Run all validations for a given year"
  task :validations, [:year] => :environment do |_t, args|
    year = args[:year].to_i
    validate_environment(year)
  end

  task :validation_help => :environment do
    help = "Before running a dry run certain conditions must be met.\n" \
      "Some conditions can be validated automatically and others must be validated manually.\n" \
      "The difference is if the condition can be checked within Enroll or it is a part of another system.\n" \
      "Automatically validated conditions will raise an error and exit if not valid.\n" \
      "Manually validated conditions will only log warning to remind you to validate them.\n\n" \
      "Those that are validated automatically are:\n" \
      "  - Income thresholds must be present for the given year\n" \
      "  - Date of record must be in the previous year to the given year\n" \
      "Those that must be validated manually are:\n" \
      "  - Affordability thresholds must be set for the given year\n\n" \
      "Usage: rake dry_run:validations[year]\n" \
      "Example: rake dry_run:validations[2024]\n" \

      puts help
  end

  def validate_environment(year)
    log "Validating the environment for #{year}"

    # Run validations. These will raise an error and exit if not valid.
    validate_income_thresholds(year)
    validate_date_of_record(year)

    log "Environment validation successful for #{year}"
  rescue ValidationFailed => e
    log "Environment validation failed for #{year}: #{e.message}"
    exit 1
  end

  def validate_income_thresholds(year)
    earned_threshold_income = EnrollRegistry[:dependent_income_filing_thresholds].setting("earned_income_filing_threshold_#{year}")&.item
    unearned_threshold_income = EnrollRegistry[:dependent_income_filing_thresholds].setting("unearned_income_filing_threshold_#{year}")&.item

    unless earned_threshold_income.present? && unearned_threshold_income.present?
      raise ValidationFailed, "Income thresholds are missing for #{year}"
    end
  end

  def validate_date_of_record(year)
    current_year = TimeKeeper.date_of_record.year
    raise ValidationFailed, "TimeKeeper.date_of_record.year is #{current_year}. Please set the date of record or dry-run year to #{year.pred}" if current_year.next != year
  end

  def warn_affordability_thresholds(year)
    log "ATTENTION: Affordability thresholds must be set for #{year} in the following files: \n" \
          "\t- medicaid_gateway/app/models/types.rb\n" \
          "\t- medicaid_gateway/components/mitc_service/spec/dummy/app/models/types.rb\n\n" \
          "Try https://www.google.com/search?q=#{year}+ACA+Affordability+Rate for the correct values."
  end

  class ValidationFailed < StandardError; end
end
