require_relative 'helpers'

namespace :dry_run do
  desc "Run all validations for a given year"
  task :validations, [:year] => :environment do |_t, args|
    year = args[:year].to_i
    validate_environment(year)
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

  class ValidationFailed < StandardError; end
end
