# frozen_string_literal: true

# This script generates a report to list all the Financial Applications
# rails runner script/daily_faa_submission_report.rb -e production
require 'csv'
field_names = %w[Primary HBX ID
                 Application ID
                 Age
                 UQHP
                 APTC/CSR
                 Magi Medicaid
                 Non-Magi
                 Date/Timestamp
                 ]

logger_field_names = %w[id Backtrace]

report_file_name = "#{Rails.root}/daily_faa_submission_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
logger_file_name = "#{Rails.root}/daily_faa_submission_report_logger_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
start_time = TimeKeeper.date_of_record.prev_day.beginning_of_day
end_time = TimeKeeper.date_of_record.prev_day.end_of_day

CSV.open(logger_file_name, 'w', force_quotes: true) do |logger_csv|
  logger_csv << logger_field_names
  CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
    report_csv << field_names
    applications = FinancialAssistance::Application.where(:submitted_at => {:"$gte" => start_time, :"$lte" => end_time})
    applications.each do |application|
      application.applicants.each do |applicant|
        age = applicant.age_on(end_time)
        uqhp_eligble = applicant.is_without_assistance
        aptc = applicant.is_ia_eligible?
        medicaid_eligible = applicant.is_medicaid_chip_eligible?
        non_magi_medicaid_eligible = applicant.is_non_magi_medicaid_eligible
        report_csv << [application.primary_applicant.person_hbx_id, application.id, age, uqhp_eligble, aptc, medicaid_eligible, 
          non_magi_medicaid_eligible, application.submitted_at]
      end
    rescue StandardError => e
      logger_csv << [application.id, e.backtrace[0..5].join('\n')]
    end
  end
end 
