require 'csv'

namespace :cv3_family_failures_report do
  desc "Generate an error report from Operations::Transformers::FamilyTo::Cv3Family.new.call(family) on all Families"

  task :generate_csv => :environment do
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Define the CSV file path
    csv_file_path = Rails.root.join("cv3_family_failures_report_#{DateTime.now.strftime("%Y%m%d%H%M%S")}.csv")

    CSV.open(csv_file_path, 'wb') do |csv|
      # Define the CSV header
      csv << ['hbx_id', 'result', 'output']

      # Iterate over all Family entries
      Family.all.each do |family|
        begin
          result = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)

          # Check if the method call was successful
          if result.failure?
            csv << [family.hbx_assigned_id, 'failure', result.failure]
          else
            csv << [family.hbx_assigned_id, 'success', nil]
          end
        rescue StandardError => e
          # Catch any errors raised during the method call
          csv << [family.hbx_assigned_id, 'failure', e.message]
        end
      end
    end

    puts "Report complete. Output file is located at: #{csv_file_path}"
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    seconds_elapsed = end_time - start_time
    hr_min_sec = format("%02dhr %02dmin %02dsec", seconds_elapsed / 3600, seconds_elapsed / 60 % 60, seconds_elapsed % 60)
    puts "Total time for report to complete: #{hr_min_sec}"
  end

end
