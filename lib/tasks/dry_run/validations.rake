require_relative 'helpers'

namespace :dry_run do
  desc "Run all validations for a given year"
  task :validations, [:year] => :environment do |_t, args|
    year = args[:year].to_i
    log "Running all validations for #{year}"

    validate_environment(year)
  end

  def validate_environment(year)
    log "Validating the environment for #{year}"

    validate_income_thresholds(year)

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

  class ValidationFailed < StandardError; end
end
