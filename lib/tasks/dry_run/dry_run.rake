require_relative 'helpers'

namespace :dry_run do
  desc "Begin a dry run for a given year"
  task :all, [:year] => :environment do |_t, args|
    # This Rake task initiates a dry run for a specified year to simulate various processes.
    # It allows you to test and verify system behavior without making permanent changes to the production data.

    # Usage:
    #   rake dry_run:all[year] -- [--force] [--refresh]
    # Parameters:
    #   - 'year' (optional): The year for which the dry run will be performed.
    #     Defaults to the next year if not provided.
    # Flags:
    #   - '--force' (optional): Specify '--force' to skip the environment validation step.
    #   - '--refresh' (optional): Specify '--refresh' to perform a hard refresh, which deletes existing data.
    # Example:
    #  rake dry_run:all[2024] -- --force --refresh
    #  note: The double dashes (--) are used to separate Rake task arguments from command-line flags

    args.with_defaults(year: TimeKeeper.date_of_record.next_year.year) # Default to next year if no year is provided
    year = args[:year].to_i

    # Step 1: Ensure that the environment is valid for a dry run.
    # This step will raise an error and exit if the environment is not valid as well as remind you about any manual requirements.
    Rake::Task['dry_run:validations'].invoke(year) unless ARGV.include?('--force')

    # Step 2: Perform a hard refresh if specified. Useful for testing the dry run multiple times without an environment reset.
    Rake::Task['dry_run:data:delete_all'].invoke(year) if ARGV.include?('--refresh')

    # Step 3: Create necessary data for the dry run. This includes products, benefit packages, etc. Refer to the 'data' Rake tasks for more information.
    Rake::Task['dry_run:data:create_all'].invoke(year)

    # Step 4: Execute commands for open enrollment. This depends on the data created in the previous step.
    Rake::Task['dry_run:commands:open_enrollment'].invoke(year)

    # Step 5: Renew financial assistance applications.
    Rake::Task['dry_run:commands:renew_applications'].invoke(year)

    # Step 6: Determine application status.
    # @todo: This step should wait to be run until after the renewals are picked up and processed.
    Rake::Task['dry_run:commands:determine_applications'].invoke(year)

    # Step 7: Renew hbx_enrollments.
    Rake::Task['dry_run:commands:renew_enrollments'].invoke(year)

    # Step 8: Notify applicants.
    # @todo: This step should wait until the application determinations and enrollment renewals are all processed.
    Rake::Task['dry_run:commands:notify'].invoke(year)

    # Step 9: Generate reports for the dry run. Once all applications and enrollments are renewed and notifications are sent, generate reports to verify the expected results.
    Rake::Task['dry_run:reports:generate'].invoke(year)
  end

  desc "Display the path to the readme with usage, descriptions, steps, and expectations."
  task :help do
    puts "See enroll/lib/tasks/dry_run/README.md for more information."
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
