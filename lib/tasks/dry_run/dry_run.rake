require_relative 'helpers'

namespace :dry_run do
  desc "Begin a dry run for a given year"
  task :run, [:year] => :environment do |_t, args|
    args.with_defaults(year: TimeKeeper.date_of_record.next_year.year) # Default to next year if no year is provided
    year = args[:year].to_i

    # Ensure that the environment is valid for a dry run. This will raise an error and exit if the environment is not valid.
    Rake::Task['dry_run:validations'].invoke(year)

    Rake::Task['dry_run:data:refresh'].invoke(year)
    Rake::Task['dry_run:commands:open_enrollment'].invoke(year)
    Rake::Task['dry_run:commands:renew'].invoke(year)
    Rake::Task['dry_run:commands:determine'].invoke(year)
    Rake::Task['dry_run:commands:notify'].invoke(year)
    # Rake::Task['dry_run:reports:renewals'].invoke(year)
    # Rake::Task['dry_run:reports:determinations'].invoke(year)
    # Rake::Task['dry_run:reports:notices'].invoke(year)
  end

end
