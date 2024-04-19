require 'csv'
# This rake task generates a CSV report from a failure analysis of family to cv3 transformation. It creates a report
# where each row corresponds to a single family and has the following columns: hbx_assigned_id, result, and output. If a
# family's transformation fails, it logs the failure result or error message. The CSV report is saved in the root directory
# with the filename 'cv3_family_failures_report.csv'.
# Additionally, progress of the task and final report status are logged both to stdout and a log file 'cv3_family_failures_report.log'.
# The task supports continuing from where it left off by checking the last processed family id in 'cv3_report_last_processed_id.txt' or last failing family id in the CSV report file.
# @param
#   batch_size [Integer] the number of families to process in a single batch. Defaults to 100.
# @example
#   rake cv3_family_failures_report:generate_csv
namespace :cv3_family_failures_report do
  desc "Generate an error report from Operations::Transformers::FamilyTo::Cv3Family.new.call(family) on all Families"

  task :generate_csv, [:batch_size] => :environment do |t, args|
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    csv_file_path = Rails.root.join("cv3_family_failures_report.csv")
    last_id_file_path = Rails.root.join("cv3_family_failures_report_last_processed_id.txt")
    list_of_ids_file_path = Rails.root.join("cv3_family_failures_report_ids_to_process.txt")
    batch_size = args[:batch_size].nil? ? 100 : args[:batch_size].to_i

    def families_to_process(list_of_ids_file_path, last_id_file_path, csv_file_path)
      if File.exist?(list_of_ids_file_path)
        log "Processing families from #{list_of_ids_file_path}."
        File.read(list_of_ids_file_path).split("\n").select { |id| id.strip =~ /^\d+$/ && !id.strip.empty? }
      elsif File.exist?(last_id_file_path)
        log "Processing families from #{last_id_file_path}."
        last_family_id = File.read(last_id_file_path).strip
        families = Family.where(:hbx_assigned_id.gt => last_family_id)
        families.pluck(:hbx_assigned_id)
      elsif File.exist?(csv_file_path)
        log "Processing families from #{csv_file_path}."
        last_entry = CSV.read(csv_file_path).last
        last_family_id = last_entry&.first
        families = Family.where(:hbx_assigned_id.gt => last_family_id)
        families.pluck(:hbx_assigned_id)
      else
        Family.pluck(:hbx_assigned_id)
      end
    end

    family_ids = families_to_process(list_of_ids_file_path, last_id_file_path, csv_file_path)

    total = family_ids&.count

    if !total || total.zero?
      log "There are no families left to process."
      next
    end

    total_batches = (total.to_f / batch_size).ceil
    log "There are #{total} families to process in #{total_batches} batches of #{batch_size}."

    CSV.open(csv_file_path, 'wb') { |csv| csv << %w[family_hbx_id primary_hbx_id result output] } unless File.exist?(csv_file_path)
    # Process families in batches and write to CSV file logging progress as we go
    family_ids.sort.each_slice(batch_size).with_index do |family_id_batch, batch_number|
      families = Family.in(hbx_assigned_id: family_id_batch).to_a
      CSV.open(csv_file_path, 'ab') do |csv|
        process_family_batch(families, csv)
      end

      # write the last processed id in the batch to the file in case of interruption it will resume from the next batch
      File.write(last_id_file_path, family_id_batch.last)

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
      family_hbx_id = family.hbx_assigned_id
      primary_hbx_id = family.primary_applicant&.person&.hbx_id
      begin
        result = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        if result.failure?
          csv << [family_hbx_id, primary_hbx_id, 'failure', result.failure]
        end
      rescue StandardError => e
        csv << [family_hbx_id, primary_hbx_id, 'error', e.message]
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
