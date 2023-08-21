namespace :dry_run do
  desc "Run all validations for a given year"
  task :validations, [:year] => :environment do |_t, args|
    year = args[:year].to_i
    puts "Running all validations for #{year}"

    Rake::Task['dry_run:validate_environment'].invoke(year)
  end

  desc "Validate the environment for a dry run"
  task :validate_environment, [:year] => :environment do |_t, args|
    year = args[:year].to_i
    puts "Validating the environment for #{year}"

    # Validate the income thresholds: https://github.com/ideacrew/enroll/pull/3005/files & https://github.com/ideacrew/medicaid_gateway/pull/360/files
    unearned_threshold_income = EnrollRegistry[:dependent_income_filing_thresholds].setting("unearned_income_filing_threshold_#{year}")&.item
    earned_threshold_income = EnrollRegistry[:dependent_income_filing_thresholds].setting("earned_income_filing_threshold_#{year}")&.item
    puts "-" * 80
    puts "earned_income_filing_threshold_#{year}: #{earned_threshold_income ? earned_threshold_income : 'Not Found'}"
    puts "unearned_income_filing_threshold_#{year}: #{unearned_threshold_income ? unearned_threshold_income : 'Not Found'}"
    puts "-" * 80
    return earned_threshold_income.present? && unearned_threshold_income.present?
  end
end
