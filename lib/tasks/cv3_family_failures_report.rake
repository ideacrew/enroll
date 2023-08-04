require 'csv'
# This rake task generates a CSV report from a failure analysis of family to cv3 transformation. It creates a report
# where each row corresponds to a single family and has the following columns: hbx_id, result, and output. If a
# family's transformation fails, it logs the failure result or error message. The CSV report is saved in the root directory
# with the filename 'cv3_family_failures_report.csv'.
# Additionally, progress of the task and final report status are logged both to stdout and a log file 'cv3_family_failures_report.log'.
# The task supports continuing from where it left off by checking the last processed family id in 'cv3_report_last_processed_id.txt' or last failing family id in the CSV report file.
# @param
#   batch_size [Integer] the number of families to process in a single batch. Defaults to 100.
# @example
#   rake cv3_family_failures_report:generate_csv[100]
namespace :cv3_family_failures_report do
  desc "Generate an error report from Operations::Transformers::FamilyTo::Cv3Family.new.call(family) on all Families"

  task :generate_csv, [:batch_size] => :environment do |t, args|
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    csv_file_path = Rails.root.join("cv3_family_failures_report.csv")
    last_id_file_path = Rails.root.join("cv3_report_last_processed_id.txt")
    batch_size = args[:batch_size].nil? ? 100 : args[:batch_size].to_i

    if File.exists?(csv_file_path)
      # Ideally there is a last_id_file_path for every csv_file_path accounting for families that are processed but
      # not saved due to successful transformation, but in case there isn't, we can still
      # resume from the last family with a failure in the CSV report file.
      if File.exists?(last_id_file_path)
        last_family_id = File.read(last_id_file_path).strip
      else
        last_line = `tail -n 1 #{csv_file_path}`
        last_family_id = last_line.strip.split(',').first
      end
      families = Family.where(:hbx_assigned_id.gt => last_family_id)
      log "Resuming from family with hbx_id #{last_family_id}."
    else
      CSV.open(csv_file_path, 'wb') { |csv| csv << %w[hbx_id result output] }
      families = Family.all

    end

    total = families.count

    if total.zero?
      log "There are no families left to process."
      next
    end

    total_batches = (total.to_f / batch_size).ceil
    log "There are #{total} families to process in #{total_batches} batches of #{batch_size}."

    # Process families in batches and write to CSV file logging progress as we go
    families.asc(:hbx_assigned_id).no_timeout.each_slice(batch_size).with_index do |family_batch, batch_number|
      CSV.open(csv_file_path, 'ab') do |csv|
        process_family_batch(family_batch, csv)
      end

      # write the last processed id to the file in case of interruption
      File.write(last_id_file_path, family_batch.last.hbx_assigned_id)

      # Log progress
      progress = ((batch_number + 1).to_f / total_batches * 100).round(2)
      processed = [batch_size * (batch_number + 1), total].min
      log "Progress: #{progress}% - Processed #{processed} out of #{total} families."
      log "Time elapsed: #{time_elapsed(start_time)}."
    end

    log "Report complete. Output file is located at: #{csv_file_path}"
    log "Total time for report to complete: #{time_elapsed(start_time)}"
  end

  def process_family_batch(families, csv)
    families.each do |family|
      begin
        result = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        if result.failure?
          csv << [family.hbx_assigned_id, 'failure', result.failure]
        end
      rescue StandardError => e
        csv << [family.hbx_assigned_id, 'failure', e.message]
      end
    end
  end

  def time_elapsed(start_time)
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    seconds_elapsed = end_time - start_time
    format("%02dhr %02dmin %02dsec", seconds_elapsed / 3600, seconds_elapsed / 60 % 60, seconds_elapsed % 60)
  end

  def log(message)
    log_prefix = "[CV3 FAMILY FAILURES REPORT] "

    puts "#{log_prefix}#{message}"
    Rails.logger.info "#{log_prefix}#{message}"
    File.open(Rails.root.join('cv3_family_failures_report.log'), 'a') do |f|
      f.puts(message)
    end
  end
end
