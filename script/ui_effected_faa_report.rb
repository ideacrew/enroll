# frozen_string_literal: true

# Tthis script is only for this UI issue
# rails r script/ui_effected_faa_report.rb -e production
require 'csv'

field_names = %w[Primary_HBX_ID
                 Application_HBX_ID
                 Application_State
                 Age
                 Unemployment_Instance
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

start_date = Date.new(2021,03,01).beginning_of_day
end_date  = Date.new(2021,03,29).end_of_day
report_file_name = "#{Rails.root}/ui_effected_faa_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
logger_file_name = "#{Rails.root}/ui_effected_faa_report_logger_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

CSV.open(logger_file_name, 'w', force_quotes: true) do |logger_csv|
  logger_csv << logger_field_names
  CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
    report_csv << field_names
    applications = FinancialAssistance::Application.where(:created_at => {:"$gte" => start_date, :"$lte" => end_date})
    applications.each do |application|
      application.applicants.each do |applicant|
        age = applicant.age_on(end_time)
        unemployment_instance = applicant.has_unemployment_income 
        uqhp_eligble = applicant.is_without_assistance
        aptc = applicant.is_ia_eligible
        medicaid_eligible = applicant.is_medicaid_chip_eligible
        non_magi_medicaid_eligible = applicant.is_non_magi_medicaid_eligible
        is_totally_ineligible = applicant.is_totally_ineligible
        is_blind = applicant.is_self_attested_blind
        is_disabled = applicant.is_physically_disabled
        need_help_with_daily_living = applicant.has_daily_living_help
        report_csv << [application&.primary_applicant&.person_hbx_id, application.hbx_id, application.aasm_state, age, unemployment_instance, uqhp_eligble, aptc, medicaid_eligible,
          non_magi_medicaid_eligible, is_totally_ineligible, application.submitted_at, application.full_medicaid_determination, is_blind, is_disabled, need_help_with_daily_living]
      end
    rescue StandardError => e
      logger_csv << [application.id, e.backtrace[0..5].join('\n')]
    end
  end
end
