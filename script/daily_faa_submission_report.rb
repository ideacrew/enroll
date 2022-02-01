# frozen_string_literal: true

# This script generates a report to list all the Financial Applications
# rails runner script/daily_faa_submission_report.rb -e production
require 'csv'
field_names = %w[Primary_HBX_ID
                 Application_HBX_ID
                 Age
                 UQHP
                 APTC_CSR
                 Magi_Medicaid
                 Non_Magi
                 Is_Totally_Ineligible
                 Submitted_At
                 Full_Medicaid_Applied?
                 Blind
                 Disabled
                 Help_With_Daily_Living
                 ]

logger_field_names = %w[id Backtrace]

date = TimeKeeper.date_of_record
report_file_name = "#{Rails.root}/daily_faa_submission_report_#{date.strftime('%m_%d_%Y')}.csv"
logger_file_name = "#{Rails.root}/daily_faa_submission_report_logger_#{date.strftime('%m_%d_%Y')}.csv"
start_on = ENV['start_on']
end_on = ENV['end_on']
start_time = start_on ? Time.parse(start_on).beginning_of_day : date.prev_day.beginning_of_day
end_time = end_on ? Time.parse(end_on).end_of_day : date.prev_day.end_of_day

CSV.open(logger_file_name, 'w', force_quotes: true) do |logger_csv|
  logger_csv << logger_field_names
  CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
    report_csv << field_names
    applications = FinancialAssistance::Application.where(:submitted_at => {:"$gte" => start_time, :"$lte" => end_time})
    applications.each do |application|
      application.applicants.each do |applicant|
        age = applicant.age_on(end_time)
        uqhp_eligble = applicant.is_without_assistance
        aptc = applicant.is_ia_eligible
        medicaid_eligible = applicant.is_medicaid_chip_eligible
        non_magi_medicaid_eligible = applicant.is_non_magi_medicaid_eligible
        is_totally_ineligible = applicant.is_totally_ineligible
        is_blind = applicant.is_self_attested_blind
        is_disabled = applicant.is_physically_disabled
        need_help_with_daily_living = applicant.has_daily_living_help
        report_csv << [application&.primary_applicant&.person_hbx_id, application.hbx_id, age, uqhp_eligble, aptc, medicaid_eligible,
          non_magi_medicaid_eligible, is_totally_ineligible, application.submitted_at, application.full_medicaid_determination, is_blind, is_disabled, need_help_with_daily_living]
      end
    rescue StandardError => e
      logger_csv << [application.id, e.backtrace[0..5].join('\n')]
    end
  end
end
