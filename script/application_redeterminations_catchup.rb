# frozen_string_literal: true

# This script generates renewal_draft applications for all the eligible families.
# Eligible families are those who
#   1. newly enrolled after application renewal process(or)
#   2. missed in the first application renewal process.

# rails runner sscript/application_redeterminations_catchup.rb '2023'

assistance_year = ARGV[0].present? && ARGV[0].respond_to?(:to_i) ? ARGV[0].to_i : TimeKeeper.date_of_record.year

renewal_year = assistance_year.next

def process_operation_result(logger, params, result, total_family_ids)
  index = params[:index]
  family_id = params[:family_id]
  if result.success?
    logger.info "family_id: #{family_id}, #{index.next} of #{total_family_ids} - Success: Created Renewal Draft with application hbx_id: #{result.success.hbx_id}}"
    [result.success.hbx_id, 'Success', 'Created Renewal Draft']
  else
    errors = if result.failure.is_a?(Dry::Validation::Result)
               result.failure.errors.to_h
             else
               result.failure
             end

    logger.info "family_id: #{family_id}, #{index.next} of #{total_family_ids} - Failure: #{errors}"
    ['N/A', 'Failure', errors]
  end
end

def redeterminations_catchup(renewal_year)
  logger = Logger.new("#{Rails.root}/log/redeterminations_catchup_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.log")

  report_file_name = "#{Rails.root}/redeterminations_catchup_report.csv"
  csv_headers = %w[PrimaryHbxId FamilyID Index RenewalApplicationHbxID Outcome OutcomeMessage]

  family_ids = ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id)

  renewal_eligible_family_ids = ::FinancialAssistance::Application.by_year(
    renewal_year.pred
  ).determined.where(:family_id.in => family_ids).distinct(:family_id)

  renewed_family_ids = ::FinancialAssistance::Application.by_year(
    renewal_year
  ).where(:family_id.in => family_ids).distinct(:family_id)

  eligible_family_ids = renewal_eligible_family_ids - renewed_family_ids
  total_family_ids = eligible_family_ids.count

  CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
    report_csv << csv_headers

    eligible_family_ids.each_with_index do |family_id, index|
      primary_hbx_id = ::Family.where(id: family_id).first&.primary_person&.hbx_id
      params = { index: index, family_id: family_id.to_s, renewal_year: renewal_year }
      renew_result = ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::Renew.new.call(params)
      result = process_operation_result(logger, params, renew_result, total_family_ids)
      report_csv << ([primary_hbx_id, family_id, index.next] + result)
    rescue StandardError => e
      logger.error "family_id: #{family_id}, #{index.next} of #{total_family_ids} - Error: #{e}, backtrace: #{e.backtrace.join('\n')}"
    end
  end

  logger.info "Processed #{total_family_ids} families for renewal_year: #{renewal_year}"
end

redeterminations_catchup(renewal_year)
