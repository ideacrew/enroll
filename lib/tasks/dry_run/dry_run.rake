require_relative 'helpers'

namespace :dry_run do
  desc "Begin a dry run for a given year"
  task :all, [:year, :hard_refresh] => :environment do |_t, args|
    args.with_defaults(year: TimeKeeper.date_of_record.next_year.year) # Default to next year if no year is provided
    year = args[:year].to_i

    # Ensure that the environment is valid for a dry run. This will raise an error and exit if the environment is not valid.
    Rake::Task['dry_run:validations'].invoke(year)
    Rake::Task['dry_run:data:delete_all'].invoke(year) if args[:hard_refresh]
    Rake::Task['dry_run:data:create_all'].invoke(year)
    Rake::Task['dry_run:commands:open_enrollment'].invoke(year)
    Rake::Task['dry_run:commands:renew_applications'].invoke(year)
    # This should wait to be run until after the renewals are picked up and processed. @todo: determine how to check for this.
    Rake::Task['dry_run:commands:determine_applications'].invoke(year)
    Rake::Task['dry_run:commands:renew_enrollments'].invoke(year)
    # This should wait until the application determinations and enrollment renewals are all processed. @todo: determine how to check for this.
    Rake::Task['dry_run:commands:notify_applications'].invoke(year)
    Rake::Task['dry_run:reports:all'].invoke(year)
  end

  desc "Create the data and open enrollment"
  task :open_enrollment, [:year] => :environment do |_t, args|
    Rake::Task['dry_run:data:create_all'].invoke(args[:year])
    Rake::Task['dry_run:commands:open_enrollment'].invoke(args[:year])
  end

  desc "Open enrollment and renew all applications and enrollments"
  task :open_enrollment_and_renew, [:year] => :environment do |_t, args|
    Rake::Task['dry_run:open_enrollment'].invoke(args[:year])
    Rake::Task['dry_run:commands:renew_applications'].invoke(args[:year])
    Rake::Task['dry_run:commands:determine_applications'].invoke(args[:year])
    Rake::Task['dry_run:commands:renew_enrollments'].invoke(args[:year])
  end

end
