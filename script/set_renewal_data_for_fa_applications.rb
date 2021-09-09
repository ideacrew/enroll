# frozen_string_literal: true

# This script generates a CSV report with list of all the
# FinancialApplication::Applications with is_renewal_authorized not nil
# where we update renewal_base_year & years_to_renew.
# rails runner script/set_renewal_data_for_fa_applications.rb -e production
require 'csv'

csv_headers = %w[PrimaryHbxId PrimaryFullName ApplicationHbxId ApplicationAasmState
                 ApplicationIrsConsent ApplicationRenewalBaseYear ApplicationYearsToRenew]
report_file_name = "#{Rails.root}/set_renewal_data_for_fa_applications_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
@logger = Logger.new("#{Rails.root}/log/set_renewal_data_for_fa_applications_logger.log")

CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
  report_csv << csv_headers
  applications = ::FinancialAssistance::Application.submitted_and_after.where(:is_renewal_authorized.ne => nil)
  @logger.info "Total number of applications to be verified and processed: #{applications.count}"
  applications.inject([]) do |_arr, application|
    primary = application&.primary_applicant
    application.set_renewal_base_year if application.renewal_base_year.nil?
    report_csv << [primary&.person_hbx_id, primary&.full_name, application.hbx_id, application.aasm_state,
                   application.is_renewal_authorized, application.renewal_base_year, application.years_to_renew]
    @logger.info "Processed application with hbx_id: #{application.hbx_id}"
  rescue StandardError => e
    @logger.info "Error raised while processing application with hbx_id: #{application.hbx_id}, error: #{e.backtrace}"
  end
end
