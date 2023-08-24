require 'csv'
field_names = %w[Primary_HBX_ID
                 Application_Year
                 Application_HBX_ID
                 Age
                 UQHP
                 APTC_CSR
                 APTC_Max
                 CSR
                 Magi_Medicaid
                 Non_Magi
                 Is_Totally_Ineligible
                 Submitted_At
                 Full_Medicaid_Applied?
                 Blind
                 Disabled
                 Help_With_Daily_Living
                 Immigration_Status
                 FPL_Amount
                 Application_State]


logger_field_names = %w[id Backtrace]
date = TimeKeeper.date_of_record
year = TimeKeeper.date_of_record.year
report_file_name = "#{Rails.root}/faa_determined_and_renewals_applications_report_#{date.strftime('%m_%d_%Y')}.csv"
logger_file_name = "#{Rails.root}/faa_determined_and_renewals_applications_report_logger_#{date.strftime('%m_%d_%Y')}.csv"
family_ids = ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id)
determined_family_ids = ::FinancialAssistance::Application.by_year(year).where(:family_id.in => family_ids).distinct(:family_id)
CSV.open(logger_file_name, 'w', force_quotes: true) do |logger_csv|
  logger_csv << logger_field_names
  CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
    report_csv << field_names
    determined_family_ids.each do |family_id|
      applications_by_family = ::FinancialAssistance::Application.where(family_id: family_id)
      next if applications_by_family.by_year(year).blank?

      current_determined_application = applications_by_family.by_year(year).determined.created_asc.last
      prospective_determined_application = applications_by_family.by_year(year.succ).determined.created_asc.last
      [current_determined_application, prospective_determined_application].each do |application|
        if application.blank?
          report_csv << ["N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"]
        else
          application.applicants.each do |applicant|
            age = applicant.age_on(date.prev_day.end_of_day)
            uqhp_eligble = applicant.is_without_assistance.present?
            aptc = applicant.is_ia_eligible
            max_aptc_str = format('%.2f', applicant.eligibility_determination.max_aptc.to_f) if applicant.eligibility_determination&.max_aptc.present?
            max_aptc = max_aptc_str if applicant.is_ia_eligible
            csr_percent = applicant.csr_percent_as_integer.to_s
            medicaid_eligible = applicant.is_medicaid_chip_eligible # is_medicaid_chip_eligible stores both magi medicaid and CHIP eligibility determinations
            non_magi_medicaid_eligible = applicant.is_non_magi_medicaid_eligible
            is_totally_ineligible = applicant.is_totally_ineligible.present?
            is_blind = applicant.is_self_attested_blind
            is_disabled = applicant.is_physically_disabled
            need_help_with_daily_living = applicant.has_daily_living_help
            immigration_status = applicant.citizen_status&.humanize&.downcase&.gsub("us", "US")
            fpl_amount = applicant.magi_as_percentage_of_fpl
            application_year = application.assistance_year
            application_state = application.aasm_state
            report_csv << [application&.primary_applicant&.person_hbx_id, application_year, application.hbx_id, age, uqhp_eligble, aptc, max_aptc, csr_percent, medicaid_eligible,
                           non_magi_medicaid_eligible, is_totally_ineligible, application.submitted_at, application.full_medicaid_determination, is_blind, is_disabled, need_help_with_daily_living, immigration_status, fpl_amount, application_state]
          rescue StandardError => e
            logger_csv << [application.id, e.backtrace[0..5].join('\n')]
          end
        end
      end
    end
  end
end
