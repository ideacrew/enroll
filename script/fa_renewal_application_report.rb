# frozen_string_literal: true

# This script generates a CSV report with list of all the
# FinancialApplication::Applications that are created yesterday.
# rails runner script/fa_renewal_application_report.rb '2022' -e production
require 'csv'

csv_headers = %w[PrimaryHbxId PrimaryFullName ApplicationHbxId
                 ApplicationAasmState PredecessorApplicationHbxId]
report_file_name = "#{Rails.root}/fa_renewal_application_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
@logger = Logger.new("#{Rails.root}/log/fa_renewal_application_report_logger.log")
assistance_year = if ARGV[0].present? && ARGV[0].to_i.to_s == ARGV[0]
                    ARGV[0].to_i
                  else
                    TimeKeeper.date_of_record.year.next
                  end

CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
  report_csv << csv_headers
  applications = ::FinancialAssistance::Application.where(
    :predecessor_id.ne => nil,
    assistance_year: assistance_year
  )
  @logger.info "Total number of applications to be processed: #{applications.count}"
  applications.inject([]) do |_arr, application|
    primary = application&.primary_applicant
    predecessor_application = ::FinancialAssistance::Application.find(application.predecessor_id)
    report_csv << [primary&.person_hbx_id, primary&.full_name,
                   application.hbx_id, application.aasm_state,
                   predecessor_application.hbx_id]
    @logger.info "Processed application with hbx_id: #{application.hbx_id}"
  rescue StandardError => e
    @logger.info "Error raised while processing application with hbx_id: #{application.hbx_id}, error: #{e.backtrace}"
  end
end
